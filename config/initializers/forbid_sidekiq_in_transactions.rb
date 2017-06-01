module Sidekiq
  module Worker
    mattr_accessor :inside_after_commit
    self.inside_after_commit = false

    module ClassMethods
      module NoSchedulingFromTransactions
        NESTING = ::Rails.env.test? ? 1 : 0

        %i(perform_async perform_at perform_in).each do |name|
          define_method(name) do |*args|
            return super(*args) if Sidekiq::Worker.inside_after_commit
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
    module InsideAfterCommit
      def committed!(*)
        inside_after_commit = Sidekiq::Worker.inside_after_commit
        Sidekiq::Worker.inside_after_commit = true
        super
      ensure
        Sidekiq::Worker.inside_after_commit = inside_after_commit
      end
    end

    prepend InsideAfterCommit
  end
end
