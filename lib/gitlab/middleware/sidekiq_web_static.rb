# frozen_string_literal: true

# This module removes the X-Sendfile-Type header for /admin/sidekiq
# assets since Workhorse isn't always guaranteed to have the assets
# present on disk, such as when using Cloud Native GitLab
# containers. These assets are also small and served infrequently so it
# should be fine to do this.
module Gitlab
  module Middleware
    class SidekiqWebStatic
      SIDEKIQ_REGEX = %r{\A/admin/sidekiq/}

      def initialize(app)
        @app = app
      end

      def call(env)
        env.delete('HTTP_X_SENDFILE_TYPE') if SIDEKIQ_REGEX.match?(env['PATH_INFO'])

        @app.call(env)
      end
    end
  end
end
