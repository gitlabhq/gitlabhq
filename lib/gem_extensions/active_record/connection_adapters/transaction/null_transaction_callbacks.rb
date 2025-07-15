# frozen_string_literal: true

# rubocop:disable Gitlab/BoundedContexts -- This is a shared module
module GemExtensions
  module ActiveRecord
    module ConnectionAdapters
      module Transaction
        module NullTransactionCallbacks
          def after_commit
            yield
          end
        end
      end
    end
  end
end
# rubocop:enable Gitlab/BoundedContexts
