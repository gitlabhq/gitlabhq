# frozen_string_literal: true

module ActiveRecord
  class Base
    module SkipTransactionCheckAfterCommit
      def committed!(*args, **kwargs)
        Gitlab::ExclusiveLease.skipping_transaction_check do
          Sidekiq::Worker.skipping_transaction_check { super }
        end
      end
    end

    prepend SkipTransactionCheckAfterCommit
  end
end
