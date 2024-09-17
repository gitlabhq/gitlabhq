# frozen_string_literal: true

module Sidekiq
  module Worker
    EnqueueFromTransactionError = Class.new(StandardError)

    def self.skipping_transaction_check(&block)
      previous_skip_transaction_check = self.skip_transaction_check
      Thread.current[:sidekiq_worker_skip_transaction_check] = true
      yield
    ensure
      Thread.current[:sidekiq_worker_skip_transaction_check] = previous_skip_transaction_check
    end

    def self.skip_transaction_check
      # When transactional tests are in use, Rails calls
      # ConnectionPool#lock_thread= to ensure all application threads
      # get the same connection so they can all see the data in the
      # uncommited transaction. If Puma is in use, check the state of
      # the lock thread.
      if ::Rails.env.test?
        lock_thread = ::ApplicationRecord.connection_pool.instance_variable_get(:@lock_thread)
        return true if lock_thread && lock_thread[:sidekiq_worker_skip_transaction_check]
      end

      Thread.current[:sidekiq_worker_skip_transaction_check]
    end

    def self.inside_transaction?
      ::ApplicationRecord.inside_transaction? || ::Ci::ApplicationRecord.inside_transaction?
    end

    def self.raise_exception_for_being_inside_a_transaction?
      !skip_transaction_check && inside_transaction?
    end

    def self.raise_inside_transaction_exception(cause:)
      raise Sidekiq::Worker::EnqueueFromTransactionError, <<~MSG
      #{cause} cannot be enqueued inside a transaction as this can lead to
      race conditions when the worker runs before the transaction is committed and
      tries to access a model that has not been saved yet.

      Use an `after_commit` hook, or include `AfterCommitQueue` and use a `run_after_commit` block instead.
      MSG
    end

    module ClassMethods
      module NoEnqueueingFromTransactions
        %i[perform_async perform_at perform_in].each do |name|
          define_method(name) do |*args|
            if Sidekiq::Worker.raise_exception_for_being_inside_a_transaction?
              begin
                Sidekiq::Worker.raise_inside_transaction_exception(cause: "#{self}.#{name}")
              rescue Sidekiq::Worker::EnqueueFromTransactionError => e
                Gitlab::AppLogger.error(e.message) if ::Rails.env.production?
                Gitlab::ErrorTracking.track_and_raise_for_dev_exception(e)
              end
            end

            super(*args)
          end
        end
      end

      prepend NoEnqueueingFromTransactions
    end
  end
end

# We deliver emails using the `deliver_later` method and it uses ActiveJob
# under the hood, which later processes the email via the defined ActiveJob adapter's `enqueue` method.
# For GitLab, the ActiveJob adapter is Sidekiq (in development and production environments).
# We need to set the following up to override the ActiveJob adapater
# so as to ensure that no mailer jobs are enqueued from within a transaction.
module ActiveJob
  module QueueAdapters
    module NoEnqueueingFromTransactions
      %i[enqueue enqueue_at].each do |name|
        define_method(name) do |*args|
          if Sidekiq::Worker.raise_exception_for_being_inside_a_transaction?
            begin
              job = args.first
              Sidekiq::Worker.raise_inside_transaction_exception(
                cause: "The #{job.class} job, enqueued into the queue: #{job.queue_name}"
              )
            rescue Sidekiq::Worker::EnqueueFromTransactionError => e
              Gitlab::AppLogger.error(e.message) if ::Rails.env.production?
              Gitlab::ErrorTracking.track_and_raise_for_dev_exception(e)
            end
          end

          super(*args)
        end
      end
    end

    # This adapter is used in development & production environments.
    class SidekiqAdapter
      prepend NoEnqueueingFromTransactions
    end

    # This adapter is used in test environment.
    # If we don't override the test environment adapter,
    # we won't be seeing any failing jobs during the CI run,
    # even if we enqueue mailers from within a transaction.
    class TestAdapter
      prepend NoEnqueueingFromTransactions
    end
  end
end
