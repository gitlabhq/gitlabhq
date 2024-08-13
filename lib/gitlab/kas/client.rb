# frozen_string_literal: true

module Gitlab
  module Kas
    class Client
      TIMEOUT = 2.seconds.freeze
      JWT_AUDIENCE = 'gitlab-kas'

      STUB_CLASSES = {
        agent_tracker: Gitlab::Agent::AgentTracker::Rpc::AgentTracker::Stub,
        configuration_project: Gitlab::Agent::ConfigurationProject::Rpc::ConfigurationProject::Stub,
        autoflow: Gitlab::Agent::AutoFlow::Rpc::AutoFlow::Stub,
        notifications: Gitlab::Agent::Notifications::Rpc::Notifications::Stub
      }.freeze

      ConfigurationError = Class.new(StandardError)

      def initialize
        raise ConfigurationError, 'GitLab KAS is not enabled' unless Gitlab::Kas.enabled?
        raise ConfigurationError, 'KAS internal URL is not configured' unless Gitlab::Kas.internal_url.present?
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
          flow_project: project_proto
        )

        stub_for(:autoflow)
          .cloud_event(request, metadata: metadata)
      end

      private

      def stub_for(service)
        @stubs ||= {}
        @stubs[service] ||= STUB_CLASSES.fetch(service).new(kas_endpoint_url, credentials, timeout: TIMEOUT)
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
    end
  end
end
