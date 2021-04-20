# frozen_string_literal: true

module Gitlab
  module SidekiqMiddleware
    module AdminMode
      class Server
        def call(_worker, job, _queue)
          # Not calling Gitlab::CurrentSettings.admin_mode on purpose on sidekiq middleware
          # Only when admin_mode setting is enabled can it be true here

          admin_mode_user_id = job['admin_mode_user_id']

          # Do not bypass session if this job was not enabled with admin mode on
          return yield unless admin_mode_user_id

          Gitlab::Auth::CurrentUserMode.bypass_session!(admin_mode_user_id) do
            Gitlab::AppLogger.debug("AdminMode::Server bypasses session for admin mode in job: #{job.inspect}")

            yield
          end
        end
      end
    end
  end
end
