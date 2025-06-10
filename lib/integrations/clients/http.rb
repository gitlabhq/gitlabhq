# frozen_string_literal: true

module Integrations
  module Clients
    class HTTP
      class << self
        def delete(path, options = {}, &block)
          options[:max_bytes] ||= default_max_bytes

          Gitlab::HTTP.delete(path, options, &block)
        end

        def head(path, options = {}, &block)
          options[:max_bytes] ||= default_max_bytes

          Gitlab::HTTP.head(path, options, &block)
        end

        def get(path, options = {}, &block)
          options[:max_bytes] ||= default_max_bytes

          Gitlab::HTTP.get(path, options, &block)
        end

        def post(path, options = {}, &block)
          options[:max_bytes] ||= default_max_bytes

          Gitlab::HTTP.post(path, options, &block)
        end

        def put(path, options = {}, &block)
          options[:max_bytes] ||= default_max_bytes

          Gitlab::HTTP.put(path, options, &block)
        end

        def try_get(path, options = {}, &block)
          options[:max_bytes] ||= default_max_bytes

          Gitlab::HTTP.try_get(path, options, &block)
        end

        private

        def default_max_bytes
          Gitlab::CurrentSettings.max_http_response_size_limit.megabytes
        end
      end
    end
  end
end
