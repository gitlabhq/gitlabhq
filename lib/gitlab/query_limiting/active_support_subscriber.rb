module Gitlab
  module QueryLimiting
    class ActiveSupportSubscriber < ActiveSupport::Subscriber
      attach_to :active_record

      def sql(event)
        unless event.payload[:name] == 'CACHE'
          Transaction.current&.increment
        end
      end
    end
  end
end
