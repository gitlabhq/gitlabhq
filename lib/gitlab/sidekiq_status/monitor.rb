# frozen_string_literal: true

module Gitlab
  module SidekiqStatus
    class Monitor < Daemon
      include ::Gitlab::Utils::StrongMemoize

      NOTIFICATION_CHANNEL = 'sidekiq:cancel:notifications'.freeze

      def start_working
        Sidekiq.logger.info "Watching sidekiq monitor"

        ::Gitlab::Redis::SharedState.with do |redis|
          redis.subscribe(NOTIFICATION_CHANNEL) do |on|
            on.message do |channel, message|
              Sidekiq.logger.info "Received #{message} on #{channel}..."
              execute_job_cancel(message)
            end
          end
        end
      end

      def self.cancel_job(jid)
        Gitlab::Redis::SharedState.with do |redis|
          redis.publish(NOTIFICATION_CHANNEL, jid)
          "Notification sent. Job should be cancelled soon. Check log to confirm. Jid: #{jid}"
        end
      end

      private

      def execute_job_cancel(jid)
        Gitlab::SidekiqMiddleware::JobsThreads.mark_job_as_cancelled(jid)

        thread = Gitlab::SidekiqMiddleware::JobsThreads
          .interrupt(jid)

        if thread
          Sidekiq.logger.info "Interrupted thread: #{thread} for #{jid}."
        else
          Sidekiq.logger.info "Did not find thread for #{jid}."
        end
      end
    end
  end
end
