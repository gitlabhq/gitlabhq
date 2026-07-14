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
        events_platform: Gitlab::Agent::EventsPlatform::Rpc::EventsPlatform::Stub,
        autoflow: Gitlab::Agent::AutoFlow::Rpc::AutoFlow::Stub
      }.freeze

      # Default deadline for a single subscribe stream. Chosen to sit slightly below KAS's
      # server-side `max_connection_age` (defaults to 2 hours in gitlab-agent's
      # `defaultAPIListenMaxConnectionAge`), so the client closes the stream cleanly first rather
      # than depending on the server-side cutoff or any intermediary's idle timeout.
      DEFAULT_SUBSCRIBE_DEADLINE = 110.minutes

      # Minimum wall-clock time a stream must run before a clean close is treated as "stable" and
      # the backoff is reset. Guards against the failure mode where a stream opens, dies almost
      # immediately, and we keep reconnecting with no backoff. Measured in seconds.
      STABLE_PERIOD_SECONDS = 30

      # How often the request (ack) enumerator wakes to re-check the stream deadline. Bounds how long
      # the write side lingers after the read side ends, avoiding the bidi write/read deadlock.
      ACK_POLL_INTERVAL_SECONDS = 1

      # Sentinel telling the request enumerator to stop forwarding acks.
      STREAM_CLOSED = :stream_closed

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
      # block, reconnecting automatically (clean close: immediately; transient gRPC error: after
      # backoff; permanent error: re-raises). Acks the broker after each successful block return; a
      # raising block leaves the event unacked for redelivery.
      #
      # Reconnects indefinitely; stop a long-running loop by raising from the block, returning a
      # truthy value from `stop_when:` (polled between attempts), or cancelling the channel
      # (`GRPC::Cancelled`, returns cleanly).
      #
      # @param topic [String] the topic to subscribe to.
      # @param consumer_group [String] the consumer group name. Multiple subscribers sharing a
      #   consumer group share load.
      # @param event_types [Array<String>] optional server-side filter on CloudEvent type names.
      # @param deadline [ActiveSupport::Duration, Numeric] maximum time to keep a single stream open
      #   before the client closes it and reconnects. Defaults to {DEFAULT_SUBSCRIBE_DEADLINE} so the
      #   client closes slightly before the server's `max_connection_age`.
      # @param stop_when [Proc, nil] optional predicate polled between attempts; when it returns
      #   truthy the loop exits cleanly.
      # @param backoff [#next, #reset] backoff strategy used between transient retries. Defaults to a
      #   fresh {Gitlab::Kas::ExponentialBackoff}.
      # @yield [event] called for each received CloudEvent.
      # @yieldparam event [Gitlab::Agent::Event::CloudEvent]
      # @return [void]
      def subscribe_events(
        topic:,
        consumer_group:,
        event_types: [],
        deadline: DEFAULT_SUBSCRIBE_DEADLINE,
        stop_when: nil,
        backoff: default_backoff,
        &block)
        raise ArgumentError, 'a block is required' unless block

        return unless Feature.enabled?(:subscribe_events_from_relay, :instance)

        logger = Gitlab::EventsPlatform::Logger.build
        consecutive_failures = 0

        loop do
          break if stop_when&.call

          # Wall-clock Time.current (not CLOCK_MONOTONIC) so specs can simulate elapsed time for the
          # stable-period check below via travel/travel_to without real sleeps.
          started_at = Time.current

          begin
            subscribe_events_single_stream(
              topic: topic,
              consumer_group: consumer_group,
              event_types: event_types,
              deadline: deadline,
              &block
            )

            if (Time.current - started_at) >= STABLE_PERIOD_SECONDS
              # Stable run: reset backoff and reconnect immediately. Low volume in practice (~once per
              # server max_connection_age per consumer), so logged at info as a liveness signal.
              backoff.reset
              consecutive_failures = 0

              logger.info(
                message: 'subscribe_events stream closed cleanly; reconnecting',
                topic: topic,
                consumer_group: consumer_group)
            else
              # Clean but immediate close: throttle so a stream that opens and closes instantly does
              # not hot-loop reconnects (and flood logs). Treated like a transient failure.
              consecutive_failures += 1

              logger.warn(
                message: 'subscribe_events stream closed before stable period; backing off',
                topic: topic,
                consumer_group: consumer_group,
                consecutive_failures: consecutive_failures)

              sleep(backoff.next)
            end
          rescue GRPC::BadStatus => e
            consecutive_failures += 1

            case classify_grpc_error(e)
            when :retry
              logger.warn(
                message: 'subscribe_events transient error; retrying',
                topic: topic,
                consumer_group: consumer_group,
                grpc_code: e.code,
                consecutive_failures: consecutive_failures)

              sleep(backoff.next)
            when :stop
              logger.info(
                message: 'subscribe_events explicitly cancelled; stopping',
                topic: topic,
                consumer_group: consumer_group)

              return
            when :raise
              logger.error(
                message: 'subscribe_events permanent error',
                topic: topic,
                consumer_group: consumer_group,
                grpc_code: e.code)

              raise
            end
          end
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

      # Starts an AutoFlow workflow on GitLab Relay.
      #
      # @param identity_key [String] caller-chosen idempotency key.
      #   (e.g. "cd-rollout-42")
      # @param workflow_definition [String] the workflow program bytes.
      #   (e.g. "def main(w, *args, **kwargs):\n    pass\n")
      # @param namespace_id [Integer] GitLab namespace or organization the workflow belongs to.
      # @param args [Array] positional arguments bound to the workflow's main().
      #   (e.g. ["production", 3])
      # @param kwargs [Hash{String => Object}] named arguments bound to the workflow's main().
      #   (e.g. { "environment" => { "id" => "42" }, "version_set" => { "services" => [...] } })
      # @return [Gitlab::Agent::AutoFlow::Rpc::StartWorkflowResponse]
      def start_workflow(identity_key:, workflow_definition:, namespace_id:, args: [], kwargs: {})
        request = Gitlab::Agent::AutoFlow::Rpc::StartWorkflowRequest.new(
          identity_key: identity_key,
          workflow_definition: workflow_definition,
          namespace_id: namespace_id,
          args: Autoflow::ValueConverter.values(args),
          kwargs: Autoflow::ValueConverter.named_values(kwargs)
        )

        stub_for(:autoflow).start_workflow(request, metadata: metadata)
      end

      private

      # Opens a single Subscribe stream and yields each received CloudEvent to the block, acking the
      # broker after each successful block return. Returns when the stream closes cleanly; raises on
      # gRPC errors or if the block raises. This is the non-resilient core that {#subscribe_events}
      # wraps in a reconnect loop.
      #
      # @return [void]
      def subscribe_events_single_stream(topic:, consumer_group:, event_types:, deadline:)
        ack_queue = Queue.new
        absolute_deadline = subscribe_deadline(deadline)

        requests = Enumerator.new do |y|
          # First message must be SubscribeConfig; the rest are acks queued by the response loop.
          y << Gitlab::Agent::EventsPlatform::Rpc::SubscribeRequest.new(
            config: Gitlab::Agent::EventsPlatform::Rpc::SubscribeConfig.new(
              topic: topic,
              consumer_group: consumer_group,
              event_types: event_types
            )
          )

          # gRPC runs this (write) loop in its own thread and joins it from inside the response
          # iteration when the stream ends, so blocking forever on `ack_queue.pop` would deadlock the
          # whole call. Self-terminate against the call deadline (read side is guaranteed done by
          # then); STREAM_CLOSED short-circuits the clean-close and block-raise paths.
          loop do
            remaining = absolute_deadline - Process.clock_gettime(Process::CLOCK_REALTIME)
            break if remaining <= 0

            msg = ack_queue.pop(timeout: [remaining, ACK_POLL_INTERVAL_SECONDS].min)
            break if msg == STREAM_CLOSED

            next if msg.nil? # poll timeout

            y << msg
          end
        end

        # Pass an explicit deadline because the stub-level timeout would kill the streaming RPC.
        responses = stub_for(:events_platform).subscribe(
          requests,
          deadline: absolute_deadline,
          metadata: metadata
        )

        begin
          responses.each do |response|
            yield response.event

            # Ack only after a successful block return, so a raising block leaves the event
            # unacknowledged for redelivery (at-least-once contract).
            ack_queue.push(
              Gitlab::Agent::EventsPlatform::Rpc::SubscribeRequest.new(
                ack: Gitlab::Agent::EventsPlatform::Rpc::Ack.new(
                  message_ids: [response.message_id]
                )
              )
            )
          end
        ensure
          ack_queue.push(STREAM_CLOSED)
        end
      end

      def default_backoff
        Gitlab::Kas::ExponentialBackoff.new(min: 1, max: 30, jitter: true)
      end

      # Absolute deadline as seconds-from-epoch. gRPC rejects an `ActiveSupport::TimeWithZone` (from
      # `Time.current`) with "bad input: (time)->c_timeval"; CLOCK_REALTIME also matches the clock the
      # gRPC c-core reads and is immune to Timecop in specs.
      def subscribe_deadline(deadline)
        Process.clock_gettime(Process::CLOCK_REALTIME) + deadline.to_f
      end

      # Maps a gRPC error to a reconnect action. Unlisted statuses default to :retry so a transient
      # blip never silently terminates a long-running consumer; the code is logged so a reviewer can
      # reclassify if needed.
      #
      # @param error [GRPC::BadStatus]
      # @return [Symbol] one of :retry, :stop, :raise
      def classify_grpc_error(error)
        case error
        when GRPC::Unavailable, GRPC::DeadlineExceeded, GRPC::Aborted,
          GRPC::Internal, GRPC::Unauthenticated
          :retry
        when GRPC::Cancelled
          :stop
        when GRPC::InvalidArgument, GRPC::NotFound, GRPC::PermissionDenied,
          GRPC::FailedPrecondition
          :raise
        else
          :retry # default: be optimistic, surface in logs
        end
      end

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
