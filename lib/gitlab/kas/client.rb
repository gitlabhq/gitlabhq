# frozen_string_literal: true

module Gitlab
  module Kas
    class Client
      JWT_AUDIENCE = 'gitlab-kas'

      STUB_CLASSES = {
        server_info: Gitlab::Agent::ServerInfo::Rpc::ServerInfo::Stub,
        agent_tracker: Gitlab::Agent::AgentTracker::Rpc::AgentTracker::Stub,
        configuration_project: Gitlab::Agent::ConfigurationProject::Rpc::ConfigurationProject::Stub,
        notifications: Gitlab::Agent::Notifications::Rpc::Notifications::Stub,
        managed_resources: Gitlab::Agent::ManagedResources::Rpc::Provisioner::Stub,
        events_platform: Gitlab::Agent::EventsPlatform::Rpc::EventsPlatform::Stub
      }.freeze

      # Default deadline for a single subscribe stream. Chosen to sit slightly below KAS's
      # server-side `max_connection_age` (defaults to 2 hours in gitlab-agent's
      # `defaultAPIListenMaxConnectionAge`), so the client closes the stream cleanly first rather
      # than depending on the server-side cutoff or any intermediary's idle timeout.
      DEFAULT_SUBSCRIBE_DEADLINE = 110.minutes

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

      def get_connected_agentks_by_agent_ids(agent_ids:)
        request = Gitlab::Agent::AgentTracker::Rpc::GetConnectedAgentksByAgentIDsRequest.new(agent_ids: agent_ids)

        stub_for(:agent_tracker)
         .get_connected_agentks_by_agent_i_ds(request, metadata: metadata)
         .agents
         .to_a
      end

      def list_agent_config_files(project:)
        request = Gitlab::Agent::ConfigurationProject::Rpc::ListAgentConfigFilesRequest.new(
          repository: repository(project),
          gitaly_info: gitaly_info(project)
        )

        stub_for(:configuration_project)
          .list_agent_config_files(request, metadata: metadata(
            project: ::Feature::Kas.project_actor(project),
            group: ::Feature::Kas.group_actor(project)
          ))
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
          .git_push_event(request, metadata: metadata(
            project: ::Feature::Kas.project_actor(project),
            group: ::Feature::Kas.group_actor(project)
          ))
      end

      # Publishes one or more CloudEvents to the events_platform service in GitLab Relay.
      #
      # @param topic [String] the topic to publish to (e.g., "gitlab.events").
      # @param events [Gitlab::Agent::Event::CloudEvent, Array<Gitlab::Agent::Event::CloudEvent>]
      #   a single CloudEvent or an array of CloudEvents.
      # @return [Array<String>] the broker message IDs assigned to the published events.
      #   Returns an empty array when `events` is `nil` or empty (no RPC call is made).
      def publish_events(topic:, events:)
        return [] unless Feature.enabled?(:publish_events_to_relay, :instance)

        events = Array.wrap(events)
        return [] if events.empty?

        request = Gitlab::Agent::EventsPlatform::Rpc::PublishRequest.new(
          topic: topic,
          events: events
        )

        stub_for(:events_platform)
          .publish(request, metadata: metadata)
          .message_ids
          .to_a
      end

      # Subscribes to a topic on Relay's events_platform and yields each received CloudEvent to the
      # given block. Acknowledges the broker after each successful block return; if the block raises,
      # the in-flight event is NOT acknowledged and will be redelivered to another consumer in the
      # group.
      #
      # The method loops until the server closes the stream (Relay shutdown, max connection age,
      # deadline expiration, network error) or the block raises. It does NOT auto-reconnect; callers
      # that need a long-lived subscription should wrap this method in a reconnect loop (see the
      # planned `subscribe_events_resilient` wrapper).
      #
      # There is no custom stop API; long-running callers signal shutdown by raising a sentinel
      # exception from inside the block.
      #
      # @param topic [String] the topic to subscribe to.
      # @param consumer_group [String] the consumer group name. Multiple subscribers sharing a
      #   consumer group share load.
      # @param event_types [Array<String>] optional server-side filter on CloudEvent type names.
      # @param deadline [ActiveSupport::Duration, Numeric] maximum time to keep the stream open
      #   before the client closes it. Defaults to {DEFAULT_SUBSCRIBE_DEADLINE} so the client
      #   closes slightly before the server's `max_connection_age`. Callers managing their own
      #   reconnect loop may tune this.
      # @yield [event] called for each received CloudEvent.
      # @yieldparam event [Gitlab::Agent::Event::CloudEvent]
      # @return [void] returns when the stream closes cleanly.
      def subscribe_events(topic:, consumer_group:, event_types: [], deadline: DEFAULT_SUBSCRIBE_DEADLINE)
        raise ArgumentError, 'a block is required' unless block_given?

        return unless Feature.enabled?(:subscribe_events_from_relay, :instance)

        ack_queue = SizedQueue.new(1)

        requests = Enumerator.new do |y|
          # First message must be SubscribeConfig.
          y << Gitlab::Agent::EventsPlatform::Rpc::SubscribeRequest.new(
            config: Gitlab::Agent::EventsPlatform::Rpc::SubscribeConfig.new(
              topic: topic,
              consumer_group: consumer_group,
              event_types: event_types
            )
          )

          # Then forward acks as the response loop queues them. A nil sentinel
          # terminates the request stream.
          loop do
            msg = ack_queue.pop
            break if msg.nil?

            y << msg
          end
        end

        # Pass an explicit deadline because the stub-level timeout would kill the streaming RPC.
        responses = stub_for(:events_platform).subscribe(
          requests,
          deadline: Time.current + deadline,
          metadata: metadata
        )

        begin
          responses.each do |response|
            yield response.event

            # Ack only on successful block return so a raising block leaves
            # the event unacknowledged for redelivery (at-least-once contract).
            ack_queue.push(
              Gitlab::Agent::EventsPlatform::Rpc::SubscribeRequest.new(
                ack: Gitlab::Agent::EventsPlatform::Rpc::Ack.new(
                  message_ids: [response.message_id]
                )
              )
            )
          end
        ensure
          # Close the request stream so the gRPC client thread can exit, whether
          # we leave via block-raise, stream close, or normal completion. With
          # SizedQueue(1), this push blocks briefly if a pending ack hasn't been
          # drained yet - that is intentional, so the last ack is delivered before
          # the stream closes.
          ack_queue.push(nil)
        end
      end

      def get_environment_template(agent:, template_name:)
        project = agent.project

        request = Gitlab::Agent::ManagedResources::Rpc::GetEnvironmentTemplateRequest.new(
          template_name: template_name,
          agent_name: agent.name,
          gitaly_info: gitaly_info(project),
          gitaly_repository: repository(project),
          default_branch: project.default_branch_or_main
        )

        stub_for(:managed_resources)
          .get_environment_template(request, metadata: metadata(
            project: ::Feature::Kas.project_actor(project),
            group: ::Feature::Kas.group_actor(project)
          ))
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
          .render_environment_template(request, metadata: metadata(
            project: ::Feature::Kas.project_actor(environment.project),
            group: ::Feature::Kas.group_actor(environment.project)
          ))
          .template
      end

      def ensure_environment(template:, environment:, build:)
        request = Gitlab::Agent::ManagedResources::Rpc::EnsureEnvironmentRequest.new(
          template: Gitlab::Agent::ManagedResources::RenderedEnvironmentTemplate.new(
            name: template.name,
            data: template.data),
          info: templating_info(environment:, build:))
        stub_for(:managed_resources)
          .ensure_environment(request, metadata: metadata(
            project: ::Feature::Kas.project_actor(environment.project),
            group: ::Feature::Kas.group_actor(environment.project)
          ))
      end

      def delete_environment(managed_resource:)
        request = ::Gitlab::Agent::ManagedResources::Rpc::DeleteEnvironmentRequest.new(
          agent_id: managed_resource.cluster_agent_id,
          project_id: managed_resource.project_id,
          environment_slug: managed_resource.environment.slug,
          objects: managed_resource.tracked_objects
        )

        stub_for(:managed_resources).delete_environment(request, metadata: metadata(
          project: ::Feature::Kas.project_actor(managed_resource.project),
          group: ::Feature::Kas.group_actor(managed_resource.project)
        ))
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

      def metadata(**feature_flag_actors)
        {
          'authorization' => "bearer #{token}",
          **::Feature::Kas.server_feature_flags_for_grpc_request(**feature_flag_actors)
        }
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

        # compatible with Gitlab::Kubernetes::DefaultNamespace
        suffix = "-#{project.id}-#{environment.slug}"
        sanitized_project_path = Gitlab::NamespaceSanitizer.sanitize(project.path.downcase).first(63 - suffix.length)
        legacy_namespace = "#{sanitized_project_path}#{suffix}"

        Gitlab::Agent::ManagedResources::TemplatingInfo.new(
          agent: Gitlab::Agent::ManagedResources::Agent.new(
            id: agent.id,
            name: agent.name,
            url: agent_url(agent.project, agent.name)),
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
          user: Gitlab::Agent::ManagedResources::User.new(id: build.user_id, username: build.user.username),
          legacy_namespace: legacy_namespace
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
