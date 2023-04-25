# frozen_string_literal: true

require 'digest'
require 'msgpack'

module Gitlab
  module SidekiqMiddleware
    module DuplicateJobs
      # This class defines an identifier of a job in a queue
      # The identifier based on a job's class and arguments.
      #
      # As strategy decides when to keep track of the job in redis and when to
      # remove it.
      #
      # Storing the deduplication key in redis can be done by calling `check!`
      # check returns the `jid` of the job if it was scheduled, or the `jid` of
      # the duplicate job if it was already scheduled
      #
      # When new jobs can be scheduled again, the strategy calls `#delete`.
      class DuplicateJob
        include Gitlab::Utils::StrongMemoize

        DEFAULT_DUPLICATE_KEY_TTL = 6.hours
        DEFAULT_STRATEGY = :until_executing
        STRATEGY_NONE = :none

        attr_reader :existing_jid

        def initialize(job, queue_name)
          @job = job
          @queue_name = queue_name
        end

        # This will continue the middleware chain if the job should be scheduled
        # It will return false if the job needs to be cancelled
        def schedule(&block)
          Strategies.for(strategy).new(self).schedule(job, &block)
        end

        # This will continue the server middleware chain if the job should be
        # executed.
        # It will return false if the job should not be executed.
        def perform(&block)
          Strategies.for(strategy).new(self).perform(job, &block)
        end

        # This method will return the jid that was set in redis
        def check!(expiry = duplicate_key_ttl)
          my_cookie = {
            'jid' => jid,
            'offsets' => {},
            'wal_locations' => {},
            'existing_wal_locations' => job_wal_locations
          }

          # There are 3 possible scenarios. In order of decreasing likelyhood:
          # 1. SET NX succeeds.
          # 2. SET NX fails, GET succeeds.
          # 3. SET NX fails, the key expires and GET fails. In this case we must retry.
          actual_cookie = {}
          while actual_cookie.empty?
            set_succeeded = with_redis { |r| r.set(cookie_key, my_cookie.to_msgpack, nx: true, ex: expiry) }
            actual_cookie = set_succeeded ? my_cookie : get_cookie
          end

          job['idempotency_key'] = idempotency_key

          self.existing_wal_locations = actual_cookie['existing_wal_locations']
          self.existing_jid = actual_cookie['jid']
        end

        def update_latest_wal_location!
          return unless job_wal_locations.present?

          argv = []
          job_wal_locations.each do |connection_name, location|
            argv += [connection_name, pg_wal_lsn_diff(connection_name), location]
          end

          with_redis { |r| r.eval(UPDATE_WAL_COOKIE_SCRIPT, keys: [cookie_key], argv: argv) }
        end

        # Generally speaking, updating a Redis key by deserializing and
        # serializing it on the Redis server is bad for performance. However in
        # the case of DuplicateJobs we know that key updates are rare, and the
        # most common operations are setting, getting and deleting the key. The
        # aim of this design is to make the common operations as fast as
        # possible.
        UPDATE_WAL_COOKIE_SCRIPT = <<~LUA
          local cookie_msgpack = redis.call("get", KEYS[1])
          if not cookie_msgpack then
            return
          end
          local cookie = cmsgpack.unpack(cookie_msgpack)

          for i = 1, #ARGV, 3 do
            local connection = ARGV[i]
            local current_offset = cookie.offsets[connection]
            local new_offset = tonumber(ARGV[i+1])
            if not current_offset or current_offset < new_offset then
              cookie.offsets[connection] = new_offset
              cookie.wal_locations[connection] = ARGV[i+2]
            end
          end

          redis.call("set", KEYS[1], cmsgpack.pack(cookie), "ex", redis.call("ttl", KEYS[1]))
        LUA

        def latest_wal_locations
          return {} unless job_wal_locations.present?

          strong_memoize(:latest_wal_locations) do
            get_cookie.fetch('wal_locations', {})
          end
        end

        def delete!
          with_redis { |redis| redis.del(cookie_key) }
        end

        def reschedule
          Gitlab::SidekiqLogging::DeduplicationLogger.instance.rescheduled_log(job)

          worker_klass.perform_async(*arguments)
        end

        def scheduled?
          scheduled_at.present?
        end

        def duplicate?
          raise "Call `#check!` first to check for existing duplicates" unless existing_jid

          jid != existing_jid
        end

        def set_deduplicated_flag!(expiry = duplicate_key_ttl)
          return unless reschedulable?

          with_redis { |redis| redis.eval(DEDUPLICATED_SCRIPT, keys: [cookie_key]) }
        end

        DEDUPLICATED_SCRIPT = <<~LUA
          local cookie_msgpack = redis.call("get", KEYS[1])
          if not cookie_msgpack then
            return
          end
          local cookie = cmsgpack.unpack(cookie_msgpack)
          cookie.deduplicated = "1"
          redis.call("set", KEYS[1], cmsgpack.pack(cookie), "ex", redis.call("ttl", KEYS[1]))
        LUA

        def should_reschedule?
          reschedulable? && get_cookie['deduplicated'].present?
        end

        def scheduled_at
          job['at']
        end

        def options
          # Remove line below when FF `ci_pipeline_process_worker_dedup_until_executed` is removed
          return job_deduplication[:options] if job_deduplication[:options]
          return {} unless worker_klass
          return {} unless worker_klass.respond_to?(:get_deduplication_options)

          worker_klass.get_deduplication_options
        end

        def idempotent?
          return false unless worker_klass
          return false unless worker_klass.respond_to?(:idempotent?)

          worker_klass.idempotent?
        end

        def duplicate_key_ttl
          options[:ttl] || DEFAULT_DUPLICATE_KEY_TTL
        end

        private

        attr_writer :existing_wal_locations
        attr_reader :queue_name, :job
        attr_writer :existing_jid

        def worker_klass
          @worker_klass ||= worker_class_name.to_s.safe_constantize
        end

        def job_wal_locations
          job['wal_locations'] || {}
        end

        def pg_wal_lsn_diff(connection_name)
          model = Gitlab::Database.database_base_models[connection_name.to_sym]

          model.connection.load_balancer.wal_diff(
            job_wal_locations[connection_name],
            existing_wal_locations[connection_name]
          )
        end

        def strategy
          # Remove line below when FF `ci_pipeline_process_worker_dedup_until_executed` is removed
          return job_deduplication[:strategy] if job_deduplication[:strategy]
          return DEFAULT_STRATEGY unless worker_klass
          return DEFAULT_STRATEGY unless worker_klass.respond_to?(:idempotent?)
          return STRATEGY_NONE unless worker_klass.deduplication_enabled?

          worker_klass.get_deduplicate_strategy
        end

        # Returns the deduplicate settings stored in the job itself; remove this method
        # when FF `ci_pipeline_process_worker_dedup_until_executed` is removed
        def job_deduplication
          return {} unless job['deduplicate']

          # Sometimes this setting is returned with all string keys/values; we need
          # to ensure the keys and values of the hash are fully symbolized or numeric
          job['deduplicate'].deep_symbolize_keys.tap do |hash|
            hash[:strategy] = hash[:strategy]&.to_sym
            hash[:options]&.each do |k, v|
              hash[:options][k] = k == :ttl ? v.to_i : v.to_sym
            end
          end.compact
        end
        strong_memoize_attr :job_deduplication

        def worker_class_name
          job['class']
        end

        def arguments
          job['args']
        end

        def jid
          job['jid']
        end

        def cookie_key
          # This duplicates `Gitlab::Redis::Queues::SIDEKIQ_NAMESPACE` both here and in `#idempotency_key`
          # This is because `Sidekiq.redis` used to add this prefix automatically through `redis-namespace`
          # and we did not notice this in https://gitlab.com/gitlab-org/gitlab/-/merge_requests/25447
          # Now we're keeping this as-is to avoid a key-migration when redis-namespace gets
          # removed from Sidekiq: https://gitlab.com/groups/gitlab-com/gl-infra/-/epics/944
          "#{Gitlab::Redis::Queues::SIDEKIQ_NAMESPACE}:#{idempotency_key}:cookie:v2"
        end

        def get_cookie
          with_redis { |redis| MessagePack.unpack(redis.get(cookie_key) || "\x80") }
        end

        def idempotency_key
          @idempotency_key ||= job['idempotency_key'] || "#{namespace}:#{idempotency_hash}"
        end

        def idempotency_hash
          Digest::SHA256.hexdigest(idempotency_string)
        end

        def namespace
          "#{Gitlab::Redis::Queues::SIDEKIQ_NAMESPACE}:duplicate:#{queue_name}"
        end

        def idempotency_string
          "#{worker_class_name}:#{Sidekiq.dump_json(arguments)}"
        end

        def existing_wal_locations
          @existing_wal_locations ||= {}
        end

        def reschedulable?
          !scheduled? && options[:if_deduplicated] == :reschedule_once
        end

        def with_redis(&block)
          Gitlab::Redis::Queues.with(&block) # rubocop:disable Cop/RedisQueueUsage, CodeReuse/ActiveRecord
        end
      end
    end
  end
end
