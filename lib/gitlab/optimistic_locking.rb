# frozen_string_literal: true

module Gitlab
  class OptimisticLocking # rubocop:disable Gitlab/NamespacedClass -- platform layer
    MAX_RETRIES = 100

    class << self
      def retry_lock_with_transaction(subject, max_retries = MAX_RETRIES, name:, &block)
        # prevent scope override, see https://gitlab.com/gitlab-org/gitlab/-/issues/391186
        klass = subject.is_a?(ActiveRecord::Relation) ? subject.klass : subject.class

        retry_lock(subject, max_retries, name: name) do |inner_subject|
          klass.transaction do
            yield(inner_subject)
          end
        end
      end

      def retry_lock(subject, max_retries = MAX_RETRIES, name:, &block)
        start_time = ::Gitlab::Metrics::System.monotonic_time
        retry_attempts = 0

        begin
          yield(subject)
        rescue ActiveRecord::StaleObjectError
          raise unless retry_attempts < max_retries

          subject.reset

          retry_attempts += 1
          retry
        ensure
          retry_lock_histogram.observe({}, retry_attempts)

          log_optimistic_lock_retries(
            name: name,
            retry_attempts: retry_attempts,
            start_time: start_time)
        end
      end

      def log_optimistic_lock_retries(name:, retry_attempts:, start_time:)
        return unless retry_attempts > 0

        elapsed_time = ::Gitlab::Metrics::System.monotonic_time - start_time

        retry_lock_logger.info(
          message: "Optimistic Lock released with retries",
          name: name,
          retries: retry_attempts,
          time_s: elapsed_time)
      end

      def retry_lock_logger
        @retry_lock_logger ||= Gitlab::Services::Logger.build
      end

      def retry_lock_histogram
        @retry_lock_histogram ||=
          Gitlab::Metrics.histogram(
            :gitlab_optimistic_locking_retries,
            'Number of retry attempts to execute optimistic retry lock',
            {},
            [0, 1, 2, 3, 5, 10, 50]
          )
      end
    end
  end
end
