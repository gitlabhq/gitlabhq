module Gitlab
  module Metrics
    module Subscribers
      # Class for tracking the total query duration of a transaction.
      class ActiveRecord < ActiveSupport::Subscriber
        attach_to :active_record

        def sql(event)
          return unless current_transaction

          current_transaction.increment(:sql_duration, event.duration)
        end

        private

        def current_transaction
          Transaction.current
        end
      end
    end
  end
end
