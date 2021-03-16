# frozen_string_literal: true

module Rack
  module Multipart
    class << self
      module MultipartPatch
        def extract_multipart(req, params = Rack::Utils.default_query_parser)
          log_multipart_warning(req) if log_large_multipart?

          super
        end

        def log_multipart_warning(req)
          content_length = req.content_length.to_i

          return unless content_length > log_threshold

          message = {
            message: "Large multipart body detected",
            path: req.path,
            content_length: content_length,
            correlation_id: ::Labkit::Context.correlation_id
          }

          log_warn(message)
        end

        def log_warn(message)
          warn message.to_json
        end

        def log_large_multipart?
          Gitlab::Utils.to_boolean(ENV['ENABLE_RACK_MULTIPART_LOGGING'], default: true) && Gitlab.com?
        end

        def log_threshold
          ENV.fetch('RACK_MULTIPART_LOGGING_BYTES', 100_000_000).to_i
        end
      end

      prepend MultipartPatch
    end
  end
end
