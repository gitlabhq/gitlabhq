module Sidekiq
  module Worker
    mattr_accessor :skip_transaction_check
    self.skip_transaction_check = false

    def self.skipping_transaction_check(&block)
      skip_transaction_check = self.skip_transaction_check
      self.skip_transaction_check = true
      yield
    ensure
      self.skip_transaction_check = skip_transaction_check
    end

    module ClassMethods
      module NoSchedulingFromTransactions
        NESTING = ::Rails.env.test? ? 1 : 0

        %i(perform_async perform_at perform_in).each do |name|
          define_method(name) do |*args|
            return super(*args) if Sidekiq::Worker.skip_transaction_check
            return super(*args) unless ActiveRecord::Base.connection.open_transactions > NESTING

            raise <<-MSG.strip_heredoc
              `#{self}.#{name}` cannot be called inside a transaction as this can lead to
              race conditions when the worker runs before the transaction is committed and
              tries to access a model that has not been saved yet.

              Use an `after_commit` hook, or include `AfterCommitQueue` and use a `run_after_commit` block instead.
            MSG
          end
        end
      end

      prepend NoSchedulingFromTransactions
    end
  end
end

module ActiveRecord
  class Base
    module SkipTransactionCheckAfterCommit
      def committed!(*)
        Sidekiq::Worker.skipping_transaction_check { super }
      end
    end

    prepend SkipTransactionCheckAfterCommit
  end
end
