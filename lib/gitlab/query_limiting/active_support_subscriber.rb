module Gitlab
  module QueryLimiting
    class ActiveSupportSubscriber < ActiveSupport::Subscriber
      attach_to :active_record

      def sql(*)
        Transaction.current&.increment
      end
    end
  end
end
