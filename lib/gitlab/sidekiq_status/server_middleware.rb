# frozen_string_literal: true

module Gitlab
  module SidekiqStatus
    class ServerMiddleware
      def call(_worker, job, _queue)
        yield
      ensure
        # After interruption, jobs are bulk re-enqueued with a direct `lpush` to
        # redis, so once lost, the jid is not re-added to SidekiqStatus.
        # We should avoid clearing it unless the job is truly finished.
        unless $!.is_a?(Sidekiq::Shutdown) || job_will_retry?(job) || job['deferred']
          Gitlab::SidekiqStatus.unset(job['jid'])
        end
      end

      private

      def job_will_retry?(job)
        return false unless $!

        retry_setting = job['retry']
        return false unless retry_setting

        max_retries = if retry_setting.is_a?(Integer)
                        retry_setting
                      else
                        Sidekiq.default_configuration[:max_retries] || Sidekiq::JobRetry::DEFAULT_MAX_RETRY_ATTEMPTS
                      end

        return false if max_retries <= 0

        retry_count = job['retry_count'] || -1
        retry_count + 1 < max_retries
      end
    end
  end
end
