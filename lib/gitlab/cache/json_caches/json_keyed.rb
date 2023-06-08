# frozen_string_literal: true

module Gitlab
  module Cache
    module JsonCaches
      class JsonKeyed < JsonCache
        private

        def expanded_cache_key(key)
          [namespace, key]
        end

        def write_raw(key, value, options = nil)
          raw_value = {}

          begin
            read_value = backend.read(cache_key(key))
            read_value = Gitlab::Json.parse(read_value.to_s) unless read_value.nil?
            raw_value = read_value if read_value.is_a?(Hash)
          rescue JSON::ParserError
          end

          raw_value[strategy_key_component] = value
          backend.write(cache_key(key), raw_value.to_json, options)
        end

        def read_raw(key)
          value = backend.read(cache_key(key))
          value = Gitlab::Json.parse(value.to_s) unless value.nil?
          value[strategy_key_component] if value.is_a?(Hash)
        rescue JSON::ParserError
          nil
        end

        def strategy_key_component
          Array.wrap(STRATEGY_KEY_COMPONENTS.fetch(cache_key_strategy)).compact.join(':').freeze
        end
      end
    end
  end
end
