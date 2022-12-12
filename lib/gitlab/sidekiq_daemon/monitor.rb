# frozen_string_literal: true

module Gitlab
  module SidekiqDaemon
    class Monitor < Daemon
      include ::Gitlab::Utils::StrongMemoize
      extend ::Gitlab::Utils::Override

      NOTIFICATION_CHANNEL = 'sidekiq:cancel:notifications'
      CANCEL_DEADLINE = 24.hours.seconds
      RECONNECT_TIME = 3.seconds

      # We use exception derived from `Exception`
      # to consider this as an very low-level exception
      # that should not be caught by application
      CancelledError = Class.new(Exception) # rubocop:disable Lint/InheritException

      def initialize
        super

        @jobs = {}
        @jobs_mutex = Mutex.new
      end

      override :thread_name
      def thread_name
        "job_monitor"
      end

      def within_job(worker_class, jid, queue)
        @jobs_mutex.synchronize do
          @jobs[jid] = { worker_class: worker_class, thread: Thread.current, started_at: Gitlab::Metrics::System.monotonic_time }
        end

        if cancelled?(jid)
          Sidekiq.logger.warn(
            class: self.class.to_s,
            action: 'run',
            queue: queue,
            jid: jid,
            canceled: true
          )
          raise CancelledError
        end

        yield
      ensure
        @jobs_mutex.synchronize do
          @jobs.delete(jid)
        end
      end

      def self.cancel_job(jid)
        payload = {
          action: 'cancel',
          jid: jid
        }.to_json

        ::Gitlab::Redis::SharedState.with do |redis|
          redis.setex(cancel_job_key(jid), CANCEL_DEADLINE, 1)
          redis.publish(NOTIFICATION_CHANNEL, payload)
        end
      end

      def jobs
        @jobs_mutex.synchronize do
          @jobs.dup
        end
      end

      private

      def run_thread
        return unless notification_channel_enabled?

        begin
          Sidekiq.logger.info(
            class: self.class.to_s,
            action: 'start',
            message: 'Starting Monitor Daemon'
          )

          while enabled?
            process_messages
            sleep(RECONNECT_TIME)
          end

        ensure
          Sidekiq.logger.warn(
            class: self.class.to_s,
            action: 'stop',
            message: 'Stopping Monitor Daemon'
          )
        end
      end

      def stop_working
        thread.raise(Interrupt) if thread.alive?
      end

      def process_messages
        ::Gitlab::Redis::SharedState.with do |redis|
          redis.subscribe(NOTIFICATION_CHANNEL) do |on|
            on.message do |channel, message|
              process_message(message)
            end
          end
        end
      rescue Exception => e # rubocop:disable Lint/RescueException
        Sidekiq.logger.warn(
          class: self.class.to_s,
          action: 'exception',
          message: e.message
        )

        # we re-raise system exceptions
        raise e unless e.is_a?(StandardError)
      end

      def process_message(message)
        Sidekiq.logger.info(
          class: self.class.to_s,
          channel: NOTIFICATION_CHANNEL,
          message: 'Received payload on channel',
          payload: message
        )

        message = safe_parse(message)
        return unless message

        case message['action']
        when 'cancel'
          process_job_cancel(message['jid'])
        else
          # unknown message
        end
      end

      def safe_parse(message)
        Gitlab::Json.parse(message)
      rescue JSON::ParserError
      end

      def process_job_cancel(jid)
        return unless jid

        # try to find thread without lock
        return unless find_thread_unsafe(jid)

        Thread.new do
          # try to find a thread, but with guaranteed
          # that handle for thread corresponds to actually
          # running job
          find_thread_with_lock(jid) do |thread|
            Sidekiq.logger.warn(
              class: self.class.to_s,
              action: 'cancel',
              message: 'Canceling thread with CancelledError',
              jid: jid,
              thread_id: thread.object_id
            )

            thread&.raise(CancelledError)
          end
        end
      end

      # This method needs to be thread-safe
      # This is why it passes thread in block,
      # to ensure that we do process this thread
      def find_thread_unsafe(jid)
        @jobs.dig(jid, :thread)
      end

      def find_thread_with_lock(jid)
        # don't try to lock if we cannot find the thread
        return unless find_thread_unsafe(jid)

        @jobs_mutex.synchronize do
          find_thread_unsafe(jid).tap do |thread|
            yield(thread) if thread
          end
        end
      end

      def cancelled?(jid)
        ::Gitlab::Redis::SharedState.with do |redis|
          redis.exists?(self.class.cancel_job_key(jid)) # rubocop:disable CodeReuse/ActiveRecord
        end
      end

      def self.cancel_job_key(jid)
        "sidekiq:cancel:#{jid}"
      end

      def notification_channel_enabled?
        ENV.fetch("SIDEKIQ_MONITOR_WORKER", 0).to_i.nonzero?
      end
    end
  end
end
