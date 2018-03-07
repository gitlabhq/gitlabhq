module Gitlab
  module Git
    module Storage
      class Health
        attr_reader :storage_name, :info

        def self.prefix_for_storage(storage_name)
          "#{Gitlab::Git::Storage::REDIS_KEY_PREFIX}#{storage_name}:"
        end

        def self.for_all_storages
          storage_names = Gitlab.config.repositories.storages.keys
          results_per_storage = nil

          Gitlab::Git::Storage.redis.with do |redis|
            keys_per_storage = all_keys_for_storages(storage_names, redis)
            results_per_storage = load_for_keys(keys_per_storage, redis)
          end

          results_per_storage.map do |name, info|
            info.each { |i| i[:failure_count] = i[:failure_count].value.to_i }
            new(name, info)
          end
        end

        private_class_method def self.all_keys_for_storages(storage_names, redis)
          keys_per_storage = {}
          all_keys = redis.zrange(Gitlab::Git::Storage::REDIS_KNOWN_KEYS, 0, -1)

          storage_names.each do |storage_name|
            prefix = prefix_for_storage(storage_name)

            keys_per_storage[storage_name] = all_keys.select { |key| key.starts_with?(prefix) }
          end

          keys_per_storage
        end

        private_class_method def self.load_for_keys(keys_per_storage, redis)
          info_for_keys = {}

          redis.pipelined do
            keys_per_storage.each do |storage_name, keys_future|
              info_for_storage = keys_future.map do |key|
                { name: key, failure_count: redis.hget(key, :failure_count) }
              end

              info_for_keys[storage_name] = info_for_storage
            end
          end

          info_for_keys
        end

        def self.for_failing_storages
          for_all_storages.select(&:failing?)
        end

        def initialize(storage_name, info)
          @storage_name = storage_name
          @info = info
        end

        def failing_info
          @failing_info ||= info.select { |info_for_host| info_for_host[:failure_count] > 0 }
        end

        def failing?
          failing_info.any?
        end

        def failing_on_hosts
          @failing_on_hosts ||= failing_info.map do |info_for_host|
            info_for_host[:name].split(':').last
          end
        end

        def failing_circuit_breakers
          @failing_circuit_breakers ||= failing_on_hosts.map do |hostname|
            CircuitBreaker.build(storage_name, hostname)
          end
        end

        def total_failures
          @total_failures ||= failing_info.sum { |info_for_host| info_for_host[:failure_count] }
        end
      end
    end
  end
end
