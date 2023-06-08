# frozen_string_literal: true

module Gitlab
  module Cache
    module JsonCaches
      class RedisKeyed < JsonCache
        private

        def expanded_cache_key(key)
          [namespace, key, *strategy_key_component]
        end

        def write_raw(key, value, options)
          backend.write(cache_key(key), value.to_json, options)
        end

        def read_raw(key)
          value = backend.read(cache_key(key))
          value = Gitlab::Json.parse(value.to_s) unless value.nil?
          value
        rescue JSON::ParserError
          nil
        end

        def strategy_key_component
          STRATEGY_KEY_COMPONENTS.fetch(cache_key_strategy)
        end
      end
    end
  end
end
