# frozen_string_literal: true

module Gitlab
  module Kas
    class Client
      JWT_AUDIENCE = 'gitlab-kas'

      STUB_CLASSES = {
        server_info: Gitlab::Agent::ServerInfo::Rpc::ServerInfo::Stub,
        agent_tracker: Gitlab::Agent::AgentTracker::Rpc::AgentTracker::Stub,
        configuration_project: Gitlab::Agent::ConfigurationProject::Rpc::ConfigurationProject::Stub,
        autoflow: Gitlab::Agent::AutoFlow::Rpc::AutoFlow::Stub,
        notifications: Gitlab::Agent::Notifications::Rpc::Notifications::Stub,
        managed_resources: Gitlab::Agent::ManagedResources::Rpc::Provisioner::Stub
      }.freeze

      AUTOFLOW_CI_VARIABLE_ENV_SCOPE = 'autoflow/internal-use'

      ConfigurationError = Class.new(StandardError)

      def initialize
        raise ConfigurationError, 'GitLab KAS is not enabled' unless Gitlab::Kas.enabled?
        raise ConfigurationError, 'KAS internal URL is not configured' unless Gitlab::Kas.internal_url.present?
      end

      # Return GitLab KAS server info
      # This method only returns information about a single KAS server instance without taking into account
      # that there are potentially multiple KAS replicas running, which may not have the same server info.
      # This is particularly the case during a rollout.
      def get_server_info
        request = Gitlab::Agent::ServerInfo::Rpc::GetServerInfoRequest.new

        stub_for(:server_info)
          .get_server_info(request, metadata: metadata)
          .current_server_info
      end

      def get_connected_agents_by_agent_ids(agent_ids:)
        request = Gitlab::Agent::AgentTracker::Rpc::GetConnectedAgentsByAgentIDsRequest.new(agent_ids: agent_ids)

        stub_for(:agent_tracker)
         .get_connected_agents_by_agent_i_ds(request, metadata: metadata)
         .agents
         .to_a
      end

      def list_agent_config_files(project:)
        request = Gitlab::Agent::ConfigurationProject::Rpc::ListAgentConfigFilesRequest.new(
          repository: repository(project),
          gitaly_info: gitaly_info(project)
        )

        stub_for(:configuration_project)
          .list_agent_config_files(request, metadata: metadata)
          .config_files
          .to_a
      end

      def send_git_push_event(project:)
        request = Gitlab::Agent::Notifications::Rpc::GitPushEventRequest.new(
          event: Gitlab::Agent::Event::GitPushEvent.new(
            project: Gitlab::Agent::Event::Project.new(
              id: project.id,
              full_path: project.full_path
            )
          )
        )

        stub_for(:notifications)
          .git_push_event(request, metadata: metadata)
      end

      def send_autoflow_event(project:, type:, id:, data:)
        # We only want to send events if AutoFlow is enabled and no-op otherwise
        return unless Feature.enabled?(:autoflow_enabled, project)

        # retrieve all AutoFlow-relevant variables
        variables = project.variables.by_environment_scope(AUTOFLOW_CI_VARIABLE_ENV_SCOPE)

        project_proto = Gitlab::Agent::Event::Project.new(
          id: project.id,
          full_path: project.full_path
        )
        request = Gitlab::Agent::AutoFlow::Rpc::CloudEventRequest.new(
          event: Gitlab::Agent::Event::CloudEvent.new(
            id: id,
            source: "GitLab",
            spec_version: "v1",
            type: type,
            attributes: {
              datacontenttype: Gitlab::Agent::Event::CloudEvent::CloudEventAttributeValue.new(
                ce_string: "application/json"
              )
            },
            text_data: data.to_json
          ),
          flow_project: project_proto,
          variables: variables.to_h { |v| [v.key, v.value] }
        )

        stub_for(:autoflow)
          .cloud_event(request, metadata: metadata)
      end

      def get_environment_template(environment:, template_name:)
        project = environment.project
        return unless project && environment.cluster_agent

        request = Gitlab::Agent::ManagedResources::Rpc::GetEnvironmentTemplateRequest.new(
          template_name: template_name,
          agent_name: environment.cluster_agent.name,
          gitaly_info: gitaly_info(project),
          gitaly_repository: repository(project),
          default_branch: project.default_branch_or_main
        )

        stub_for(:managed_resources)
          .get_environment_template(request, metadata: metadata)
          .template
      end

      def get_default_environment_template
        request = Gitlab::Agent::ManagedResources::Rpc::GetDefaultEnvironmentTemplateRequest.new
        stub_for(:managed_resources)
          .get_default_environment_template(request, metadata: metadata)
          .template
      end

      def render_environment_template(template:, environment:, build:)
        request = Gitlab::Agent::ManagedResources::Rpc::RenderEnvironmentTemplateRequest.new(
          template: Gitlab::Agent::ManagedResources::EnvironmentTemplate.new(
            name: template.name,
            data: template.data),
          info: templating_info(environment:, build:))
        stub_for(:managed_resources)
          .render_environment_template(request, metadata: metadata)
          .template
      end

      def ensure_environment(template:, environment:, build:)
        request = Gitlab::Agent::ManagedResources::Rpc::EnsureEnvironmentRequest.new(
          template: Gitlab::Agent::ManagedResources::RenderedEnvironmentTemplate.new(
            name: template.name,
            data: template.data),
          info: templating_info(environment:, build:))
        stub_for(:managed_resources)
          .ensure_environment(request, metadata: metadata)
      end

      private

      def stub_for(service)
        @stubs ||= {}
        @stubs[service] ||= STUB_CLASSES.fetch(service).new(kas_endpoint_url, credentials, timeout: timeout)
      end

      def repository(project)
        gitaly_repository = project.repository.gitaly_repository

        Gitlab::Agent::Entity::GitalyRepository.new(gitaly_repository.to_h)
      end

      def gitaly_info(project)
        gitaly_features = Feature::Gitaly.server_feature_flags
        connection_data = Gitlab::GitalyClient.connection_data(project.repository_storage)
          .merge(features: gitaly_features)

        Gitlab::Agent::Entity::GitalyInfo.new(connection_data)
      end

      def kas_endpoint_url
        Gitlab::Kas.internal_url.sub(%r{^grpcs?://}, '')
      end

      def credentials
        if URI(Gitlab::Kas.internal_url).scheme == 'grpcs'
          GRPC::Core::ChannelCredentials.new(::Gitlab::X509::Certificate.ca_certs_bundle)
        else
          :this_channel_is_insecure
        end
      end

      def metadata
        { 'authorization' => "bearer #{token}" }
      end

      def token
        JSONWebToken::HMACToken.new(Gitlab::Kas.secret).tap do |token|
          token.issuer = Settings.gitlab.host
          token.audience = JWT_AUDIENCE
        end.encoded
      end

      def timeout
        Gitlab::Kas.client_timeout_seconds.seconds
      end

      def templating_info(environment:, build:)
        agent = environment.cluster_agent
        project = environment.project
        return unless agent && project && build && build.user

        Gitlab::Agent::ManagedResources::TemplatingInfo.new(
          agent: Gitlab::Agent::ManagedResources::Agent.new(
            id: agent.id,
            name: agent.name,
            url: agent_url(project, agent.name)),
          environment: Gitlab::Agent::ManagedResources::Environment.new(
            id: environment.id,
            name: environment.name,
            slug: environment.slug,
            page_url: environment_url(project, environment),
            url: environment.external_url,
            tier: environment.tier),
          project: Gitlab::Agent::ManagedResources::Project.new(
            id: project.id,
            slug: project.path,
            path: project.full_path,
            url: project.web_url),
          pipeline: Gitlab::Agent::ManagedResources::Pipeline.new(id: build.pipeline_id),
          job: Gitlab::Agent::ManagedResources::Job.new(id: build.id),
          user: Gitlab::Agent::ManagedResources::User.new(id: build.user_id, username: build.user.username)
        )
      end

      def agent_url(project, agent_name)
        Gitlab::Routing.url_helpers.project_cluster_agent_url(project, agent_name)
      end

      def environment_url(project, environment)
        Gitlab::Routing.url_helpers.project_environment_url(project, environment)
      end
    end
  end
end
