module Sidekiq
  module Worker
    module ClassMethods
      module NoSchedulingFromTransactions
        NESTING = ::Rails.env.test? ? 1 : 0

        %i(perform_async perform_at perform_in).each do |name|
          define_method(name) do |*args|
            if ActiveRecord::Base.connection.open_transactions > NESTING
              raise <<-MSG.strip_heredoc
                `#{self}.#{name}` cannot be called inside a transaction as this can lead to race
                conditions when the worker runs before the transaction is committed and tries to
                access a model that has not been saved yet.

                Schedule the worker from inside a `run_after_commit` block instead.
              MSG
            end

            super(*args)
          end
        end
      end

      prepend NoSchedulingFromTransactions
    end
  end
end
