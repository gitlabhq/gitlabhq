# frozen_string_literal: true

# This module prevents Rack::Sendfile from using sendfile for /admin/sidekiq
# assets since Workhorse isn't always guaranteed to have the assets
# present on disk, such as when using Cloud Native GitLab
# containers. These assets are also small and served infrequently so it
# should be fine to do this.
#
# Previously this middleware removed the HTTP_X_SENDFILE_TYPE header,
# but Rack 2.2.20+ no longer uses that to determine sendfile behavior.
# Since this middleware is positioned before Rack::Sendfile in the stack,
# when @app.call returns, Rack::Sendfile has already processed the response
# and added the X-Sendfile header. We remove that header and read the file
# content directly to restore the body that Rack::Sendfile emptied.
module Gitlab
  module Middleware
    class SidekiqWebStatic
      SIDEKIQ_REGEX = %r{\A/admin/sidekiq/}

      def initialize(app)
        @app = app
      end

      def call(env)
        # Check the path before calling the app, as Sidekiq may modify it
        is_sidekiq_path = SIDEKIQ_REGEX.match?(env['PATH_INFO'])

        status, headers, body = @app.call(env)

        if is_sidekiq_path && headers['X-Sendfile']
          # Rack::Sendfile has set X-Sendfile header and emptied the body.
          # We need to remove the header and read the file content directly.
          file_path = headers.delete('X-Sendfile')

          # Read the file content and return it as the body
          file_content = ::File.binread(file_path)
          headers['Content-Length'] = file_content.bytesize.to_s

          # Close the original body if needed
          body.close if body.respond_to?(:close)

          body = [file_content]
        end

        [status, headers, body]
      rescue Errno::ENOENT, Errno::EACCES
        [404, {}, ['File not found']]
      end
    end
  end
end
