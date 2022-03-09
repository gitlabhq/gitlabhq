# frozen_string_literal: true

require 'digest'

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
        WAL_LOCATION_TTL = 60.seconds
        MAX_REDIS_RETRIES = 5
        DEFAULT_STRATEGY = :until_executing
        STRATEGY_NONE = :none
        DEDUPLICATED_FLAG_VALUE = 1

        LUA_SET_WAL_SCRIPT = <<~EOS
          local key, wal, offset, ttl = KEYS[1], ARGV[1], tonumber(ARGV[2]), ARGV[3]
          local existing_offset = redis.call("LINDEX", key, -1)
          if existing_offset == false then
            redis.call("RPUSH", key, wal, offset)
            redis.call("EXPIRE", key, ttl)
          elseif offset > tonumber(existing_offset) then
            redis.call("LSET", key, 0, wal)
            redis.call("LSET", key, -1, offset)
          end
        EOS

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
          read_jid = nil
          read_wal_locations = {}

          Sidekiq.redis do |redis|
            redis.multi do |multi|
              multi.set(idempotency_key, jid, ex: expiry, nx: true)
              read_wal_locations = check_existing_wal_locations!(multi, expiry)
              read_jid = multi.get(idempotency_key)
            end
          end

          job['idempotency_key'] = idempotency_key

          # We need to fetch values since the read_wal_locations and read_jid were obtained inside transaction, under redis.multi command.
          self.existing_wal_locations = read_wal_locations.transform_values(&:value)
          self.existing_jid = read_jid.value
        end

        def update_latest_wal_location!
          return unless job_wal_locations.present?

          Sidekiq.redis do |redis|
            redis.multi do |multi|
              job_wal_locations.each do |connection_name, location|
                multi.eval(
                  LUA_SET_WAL_SCRIPT,
                  keys: [wal_location_key(connection_name)],
                  argv: [location, pg_wal_lsn_diff(connection_name).to_i, WAL_LOCATION_TTL]
                )
              end
            end
          end
        end

        def latest_wal_locations
          return {} unless job_wal_locations.present?

          strong_memoize(:latest_wal_locations) do
            read_wal_locations = {}

            Sidekiq.redis do |redis|
              redis.multi do |multi|
                job_wal_locations.keys.each do |connection_name|
                  read_wal_locations[connection_name] = multi.lindex(wal_location_key(connection_name), 0)
                end
              end
            end

            read_wal_locations.transform_values(&:value).compact
          end
        end

        def delete!
          Sidekiq.redis do |redis|
            redis.multi do |multi|
              multi.del(idempotency_key, deduplicated_flag_key)
              delete_wal_locations!(multi)
            end
          end
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

          Sidekiq.redis do |redis|
            redis.set(deduplicated_flag_key, DEDUPLICATED_FLAG_VALUE, ex: expiry, nx: true)
          end
        end

        def should_reschedule?
          return false unless reschedulable?

          Sidekiq.redis do |redis|
            redis.get(deduplicated_flag_key).present?
          end
        end

        def scheduled_at
          job['at']
        end

        def options
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

        def delete_wal_locations!(redis)
          job_wal_locations.keys.each do |connection_name|
            redis.del(wal_location_key(connection_name))
            redis.del(existing_wal_location_key(connection_name))
          end
        end

        def check_existing_wal_locations!(redis, expiry)
          read_wal_locations = {}

          job_wal_locations.each do |connection_name, location|
            key = existing_wal_location_key(connection_name)
            redis.set(key, location, ex: expiry, nx: true)
            read_wal_locations[connection_name] = redis.get(key)
          end

          read_wal_locations
        end

        def job_wal_locations
          job['wal_locations'] || {}
        end

        def pg_wal_lsn_diff(connection_name)
          model = Gitlab::Database.database_base_models[connection_name]

          model.connection.load_balancer.wal_diff(
            job_wal_locations[connection_name],
            existing_wal_locations[connection_name]
          )
        end

        def strategy
          return DEFAULT_STRATEGY unless worker_klass
          return DEFAULT_STRATEGY unless worker_klass.respond_to?(:idempotent?)
          return STRATEGY_NONE unless worker_klass.deduplication_enabled?

          worker_klass.get_deduplicate_strategy
        end

        def worker_class_name
          job['class']
        end

        def arguments
          job['args']
        end

        def jid
          job['jid']
        end

        def existing_wal_location_key(connection_name)
          "#{idempotency_key}:#{connection_name}:existing_wal_location"
        end

        def wal_location_key(connection_name)
          "#{idempotency_key}:#{connection_name}:wal_location"
        end

        def idempotency_key
          @idempotency_key ||= job['idempotency_key'] || "#{namespace}:#{idempotency_hash}"
        end

        def deduplicated_flag_key
          "#{idempotency_key}:deduplicate_flag"
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
      end
    end
  end
end
