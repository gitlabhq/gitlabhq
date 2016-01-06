module Gitlab
  module Metrics
    module Subscribers
      # Class for tracking the total query duration of a transaction.
      class ActiveRecord < ActiveSupport::Subscriber
        attach_to :active_record

        def sql(event)
          return unless current_transaction

          current_transaction.increment(:sql_duration, duration(event))
        end

        private

        def current_transaction
          Transaction.current
        end

        def duration(event)
          event.duration * 1000.0
        end
      end
    end
  end
end
