# frozen_string_literal: true

module Gitlab
  module Middleware
    class CompressedJson
      INSTANCE_PACKAGES_PATH = %r{
        \A/api/v4/packages/npm/-/npm/v1/security/
        (?:(?:advisories/bulk)|(?:audits/quick))\z (?# end)
      }xi
      GROUP_PACKAGES_PATH = %r{
        \A/api/v4/groups/
        (?<id>
        [a-zA-Z0-9%-._]{1,255}
        )/-/packages/npm/-/npm/v1/security/
        (?:(?:advisories/bulk)|(?:audits/quick))\z (?# end)
      }xi
      PROJECT_PACKAGES_PATH = %r{
        \A/api/v4/projects/
        (?<id>
        [a-zA-Z0-9%-._]{1,255}
        )/packages/npm/-/npm/v1/security/
        (?:(?:advisories/bulk)|(?:audits/quick))\z (?# end)
      }xi
      MAXIMUM_BODY_SIZE = 200.kilobytes.to_i
      UNSAFE_CHARACTERS = %r{[!"#&'()*+,./:;<>=?@\[\]^`{}|~$]}xi

      def initialize(app)
        @app = app
      end

      def call(env)
        if compressed_et_request?(env)
          input = extract(env['rack.input'])

          if input.length > MAXIMUM_BODY_SIZE
            return too_large
          end

          env.delete('HTTP_CONTENT_ENCODING')
          env['CONTENT_LENGTH'] = input.length
          env['rack.input'] = StringIO.new(input)
        end

        @app.call(env)
      end

      def compressed_et_request?(env)
        post_request?(env) &&
          gzip_encoding?(env) &&
          match_content_type?(env) &&
          match_path?(env)
      end

      def too_large
        [413, { 'Content-Type' => 'text/plain' }, ['Payload Too Large']]
      end

      def relative_url
        File.join('', Gitlab.config.gitlab.relative_url_root).chomp('/')
      end

      def extract(input)
        Zlib::GzipReader.new(input).read(MAXIMUM_BODY_SIZE + 1)
      end

      def post_request?(env)
        env['REQUEST_METHOD'] == 'POST'
      end

      def gzip_encoding?(env)
        env['HTTP_CONTENT_ENCODING'] == 'gzip'
      end

      def match_content_type?(env)
        env['CONTENT_TYPE'].nil? ||
          env['CONTENT_TYPE'] == 'application/json' ||
          env['CONTENT_TYPE'] == 'application/x-sentry-envelope'
      end

      def match_path?(env)
        match_packages_path?(env)
      end

      def match_packages_path?(env)
        path = env['PATH_INFO'].delete_prefix(relative_url)
        match_data = path.match(INSTANCE_PACKAGES_PATH) ||
          path.match(PROJECT_PACKAGES_PATH) ||
          path.match(GROUP_PACKAGES_PATH)
        return false unless match_data

        return true if match_data.names.empty? # instance level endpoint was matched

        url_encoded?(match_data[:id])
      end

      def url_encoded?(id)
        id !~ UNSAFE_CHARACTERS
      end
    end
  end
end
