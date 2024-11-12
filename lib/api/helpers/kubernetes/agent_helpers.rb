# frozen_string_literal: true

module API
  module Helpers
    module Kubernetes
      module AgentHelpers
        include Gitlab::Utils::StrongMemoize

        COUNTERS_EVENTS_MAPPING = {
          'flux_git_push_notifications_total' => 'create_flux_git_push_notification',
          'k8s_api_proxy_request' => 'request_api_proxy_access',
          'k8s_api_proxy_requests_via_ci_access' => 'request_api_proxy_access_via_ci',
          'k8s_api_proxy_requests_via_user_access' => 'request_api_proxy_access_via_user',
          'k8s_api_proxy_requests_via_pat_access' => 'request_api_proxy_access_via_pat'
        }.freeze

        def agent_token
          cluster_agent_token_from_authorization_token
        end
        strong_memoize_attr :agent_token

        def agent
          agent_token.agent
        end
        strong_memoize_attr :agent

        def check_agent_token
          unauthorized! unless agent_token

          ::Clusters::AgentTokens::TrackUsageService.new(agent_token).execute
        end

        def agent_has_access_to_project?(project)
          ::Users::Anonymous.can?(:download_code, project) || agent.has_access_to?(project)
        end

        def increment_unique_events
          events = params[:unique_counters]&.slice(
            :k8s_api_proxy_requests_unique_agents_via_ci_access,
            :k8s_api_proxy_requests_unique_agents_via_user_access,
            :k8s_api_proxy_requests_unique_agents_via_pat_access,
            :flux_git_push_notified_unique_projects
          )

          events&.each do |event, entity_ids|
            increment_unique_values(event, entity_ids)
          end
        end

        def track_events
          event_lists = params[:events]&.slice(
            :k8s_api_proxy_requests_unique_users_via_ci_access,
            :k8s_api_proxy_requests_unique_users_via_user_access,
            :k8s_api_proxy_requests_unique_users_via_pat_access,
            :register_agent_at_kas
          )
          return if event_lists.blank?

          event_lists[:agent_users_using_ci_tunnel] = event_lists.slice(
            :k8s_api_proxy_requests_unique_users_via_ci_access,
            :k8s_api_proxy_requests_unique_users_via_user_access,
            :k8s_api_proxy_requests_unique_users_via_pat_access
          ).values.compact.flatten

          users, projects = load_users_and_projects(event_lists)
          event_lists.each do |event_name, events|
            track_events_for(event_name, events, users, projects) if events
          end
        end

        def track_unique_user_events
          events = params[:unique_counters]&.slice(
            :k8s_api_proxy_requests_unique_users_via_ci_access,
            :k8s_api_proxy_requests_unique_users_via_user_access,
            :k8s_api_proxy_requests_unique_users_via_pat_access
          )
          return if events.blank?

          unique_user_ids = events.values.flatten.uniq
          users = User.id_in(unique_user_ids).index_by(&:id)

          events.each do |event, user_ids|
            user_ids.each do |user_id|
              user = users[user_id]
              next if user.nil?

              Gitlab::InternalEvents.track_event(event, user: user)
            end
          end
        end

        def increment_count_events
          counters = params[:counters]&.slice(*COUNTERS_EVENTS_MAPPING.keys)

          return unless counters.present?

          counters.each do |counter, incr|
            next if incr == 0

            event = COUNTERS_EVENTS_MAPPING[counter]

            Gitlab::InternalEvents.with_batched_redis_writes do
              incr.times { Gitlab::InternalEvents.track_event(event) }
            end
          end
        end

        def update_configuration(agent:, config:)
          ::Clusters::Agents::Authorizations::CiAccess::RefreshService.new(agent, config: config).execute
          ::Clusters::Agents::Authorizations::UserAccess::RefreshService.new(agent, config: config).execute
        end

        def retrieve_user_from_session_cookie
          # Load session
          public_session_id_string =
            begin
              Gitlab::Kas::UserAccess.decrypt_public_session_id(params[:access_key])
            rescue StandardError
              bad_request!('Invalid access_key')
            end

          session_id = Rack::Session::SessionId.new(public_session_id_string)
          session = ActiveSession.sessions_from_ids([session_id.private_id]).first
          unauthorized!('Invalid session') unless session

          # CSRF check
          unless ::Gitlab::Kas::UserAccess.valid_authenticity_token?(
            request, session.symbolize_keys, params[:csrf_token]
          )
            unauthorized!('CSRF token does not match')
          end

          # Load user
          user = Warden::SessionSerializer.new('rack.session' => session).fetch(:user)
          unauthorized!('Invalid user in session') unless user
          user
        end

        def retrieve_user_from_personal_access_token
          return unless access_token.present?

          validate_and_save_access_token!(scopes: [Gitlab::Auth::K8S_PROXY_SCOPE])

          ::PersonalAccessTokens::LastUsedService.new(access_token).execute

          access_token.user || raise(UnauthorizedError)
        end

        def access_token
          return unless params[:access_key].present?

          PersonalAccessToken.find_by_token(params[:access_key])
        end
        strong_memoize_attr :access_token

        private

        def load_users_and_projects(event_lists)
          all_events = event_lists.values.flatten.compact
          unique_user_ids = all_events.pluck('user_id').compact.uniq # rubocop:disable CodeReuse/ActiveRecord -- this pluck isn't from ActiveRecord, it's from ActiveSupport
          unique_project_ids = all_events.pluck('project_id').compact.uniq # rubocop:disable CodeReuse/ActiveRecord -- this pluck isn't from ActiveRecord, it's from ActiveSupport
          users = User.id_in(unique_user_ids).index_by(&:id)
          projects = Project.id_in(unique_project_ids).index_by(&:id)
          [users, projects]
        end

        def track_events_for(event_name, events, users, projects)
          events.each do |event|
            next if event.blank?

            user = users[event[:user_id]]
            project = projects[event[:project_id]]
            next if project.nil?

            additional_properties = {}
            if event_name.to_sym == :register_agent_at_kas
              additional_properties = { label: event[:agent_version], property: event[:architecture] }
            end

            Gitlab::InternalEvents.track_event(event_name, additional_properties: additional_properties, user: user,
              project: project)
          end
        end
      end
    end
  end
end
