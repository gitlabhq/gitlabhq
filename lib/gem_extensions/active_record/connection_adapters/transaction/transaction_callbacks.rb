# frozen_string_literal: true

# rubocop:disable Gitlab/BoundedContexts -- This is a shared module
# rubocop:disable Gitlab/ModuleWithInstanceVariables -- It's necessary here
module GemExtensions
  module ActiveRecord
    module ConnectionAdapters
      module Transaction
        module TransactionCallbacks
          def initialize(...)
            super

            @parent_transaction = connection.current_transaction
            @transaction_callbacks = []
          end

          def after_commit(&block)
            raise ArgumentError, '`after_commit` requires a block' unless block

            if run_transaction_callbacks?
              @transaction_callbacks << block
            else
              parent_transaction.after_commit(&block)
            end
          end

          def commit_records
            super

            @transaction_callbacks.each(&:call)
          end

          private

          attr_reader :parent_transaction

          def run_transaction_callbacks?
            !parent_transaction.joinable?
          end
        end
      end
    end
  end
end
# rubocop:enable Gitlab/ModuleWithInstanceVariables
# rubocop:enable Gitlab/BoundedContexts
