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

        DEFAULT_DUPLICATE_KEY_TTL = 10.minutes
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
          my_cookie = Cookie.new(
            jid: jid,
            existing_wal_locations: job_wal_locations
          )

          # Signal to any server middleware for the same idempotency_key that
          # there is at least one client middleware performing deduplication checks.
          #
          # The server middleware can determine if there is a duplicate job using the signaling key
          # instead of reading the cookie key. Using a single key, the server can atomically read and delete it.
          # This prevents a data race between the server and client in trying to read/write the key.
          #
          # There are 2 cases for deleting this key:
          # 1. Server middleware's until_executed strategy atomically reads and delete it. Reschedules if key exists.
          # 2. Client deletes key if job is not deduplicated.
          set_signaling_key(expiry)

          # There are 3 possible scenarios. In order of decreasing likelihood:
          # 1. SET NX succeeds.
          # 2. SET NX fails, GET succeeds.
          # 3. SET NX fails, the key expires and GET fails. In this case we must retry.
          actual_cookie = {}
          while actual_cookie.empty?
            write_succeeded = my_cookie.write(cookie_key, expiry)
            actual_cookie = write_succeeded ? my_cookie.cookie : get_cookie
          end

          job['idempotency_key'] = idempotency_key

          self.existing_wal_locations = actual_cookie['existing_wal_locations']
          self.existing_jid = actual_cookie['jid']
        end

        def set_signaling_key(expiry)
          return unless strategy == :until_executed && reschedulable? && job['rescheduled_once'].nil?

          with_redis { |r| r.set(reschedule_signal_key, "1", ex: expiry) }
        end

        def clear_signaling_key
          return unless strategy == :until_executed && reschedulable? && job['rescheduled_once'].nil?

          with_redis { |r| r.del(reschedule_signal_key) }
        end

        def check_and_del_reschedule_signal
          with_redis { |r| r.del(reschedule_signal_key) } == 1 # del returns 1 if key exists
        end

        def update_latest_wal_location!
          return unless job_wal_locations.present?

          argv = []
          job_wal_locations.each do |connection_name, location|
            diff = pg_wal_lsn_diff(connection_name)
            argv += [connection_name, diff ? diff.to_f : '', location]
          end

          Cookie.update_wal_locations!(cookie_key, argv)
        end

        def idempotency_key
          @idempotency_key ||= job['idempotency_key'] || "#{namespace}:#{idempotency_hash}"
        end

        def latest_wal_locations
          return {} unless job_wal_locations.present?

          strong_memoize(:latest_wal_locations) do
            get_cookie.fetch('wal_locations', {})
          end
        end

        def delete!
          Cookie.delete!(cookie_key)
        end

        def reschedule
          Gitlab::SidekiqLogging::DeduplicationLogger.instance.rescheduled_log(job)

          worker_klass.rescheduled_once.perform_async(*arguments)
        end

        def scheduled?
          scheduled_at.present?
        end

        def duplicate?
          raise "Call `#check!` first to check for existing duplicates" unless existing_jid

          jid != existing_jid
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

        def deferred?
          job['deferred']
        end

        def strategy
          return DEFAULT_STRATEGY unless worker_klass
          return DEFAULT_STRATEGY unless worker_klass.respond_to?(:idempotent?)
          return STRATEGY_NONE unless worker_klass.deduplication_enabled?

          worker_klass.get_deduplicate_strategy
        end

        def reschedulable?
          !scheduled? && options[:if_deduplicated] == :reschedule_once
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

        def worker_class_name
          job['class']
        end

        def arguments
          job['args']
        end

        def jid
          job['jid']
        end

        def reschedule_signal_key
          "#{idempotency_key}:checking_duplicate"
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
          Cookie.read(cookie_key)
        end

        def idempotency_hash
          Digest::SHA256.hexdigest(idempotency_string)
        end

        def namespace
          "#{Gitlab::Redis::Queues::SIDEKIQ_NAMESPACE}:duplicate:#{queue_name}"
        end

        def idempotency_string
          "#{worker_class_name}:#{idempotency_arguments}"
        end

        def idempotency_arguments
          args = worker_klass.try(:idempotency_arguments, arguments) || arguments

          Sidekiq.dump_json(args)
        end

        def existing_wal_locations
          @existing_wal_locations ||= {}
        end

        def with_redis(&block)
          Gitlab::Redis::QueuesMetadata.with(&block) # rubocop:disable CodeReuse/ActiveRecord
        end
      end
    end
  end
end
