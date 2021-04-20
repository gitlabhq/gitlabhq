# frozen_string_literal: true

module Gitlab
  module SidekiqMiddleware
    module AdminMode
      # Checks if admin mode is enabled for the request creating the sidekiq job
      # by examining if admin mode has been enabled for the user
      # If enabled then it injects a job field that persists through the job execution
      class Client
        def call(_worker_class, job, _queue, _redis_pool)
          # Not calling Gitlab::CurrentSettings.admin_mode on purpose on sidekiq middleware
          # Only when admin mode application setting is enabled might the admin_mode_user_id be non-nil here

          # Admin mode enabled in the original request or in a nested sidekiq job
          admin_mode_user_id = find_admin_user_id

          if admin_mode_user_id
            job['admin_mode_user_id'] ||= admin_mode_user_id

            ::Gitlab::AppLogger.debug("AdminMode::Client injected admin mode for job: #{job.inspect}")
          end

          yield
        end

        private

        def find_admin_user_id
          ::Gitlab::Auth::CurrentUserMode.current_admin&.id ||
            ::Gitlab::Auth::CurrentUserMode.bypass_session_admin_id
        end
      end
    end
  end
end
