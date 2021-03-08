# frozen_string_literal: true

module Gitlab
  module QueryLimiting
    class ActiveSupportSubscriber < ActiveSupport::Subscriber
      attach_to :active_record

      def sql(event)
        return if !Transaction.current || event.payload.fetch(:cached, event.payload[:name] == 'CACHE')

        Transaction.current.increment
        Transaction.current.executed_sql(event.payload[:sql])
      end
    end
  end
end
