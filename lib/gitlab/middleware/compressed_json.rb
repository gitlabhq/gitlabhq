# frozen_string_literal: true

module Gitlab
  module Middleware
    class CompressedJson
      COLLECTOR_PATH = '/api/v4/error_tracking/collector'
      MAXIMUM_BODY_SIZE = 200.kilobytes.to_i

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
        env['REQUEST_METHOD'] == 'POST' &&
          env['HTTP_CONTENT_ENCODING'] == 'gzip' &&
          env['CONTENT_TYPE'] == 'application/json' &&
          env['PATH_INFO'].start_with?((File.join(relative_url, COLLECTOR_PATH)))
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
    end
  end
end
