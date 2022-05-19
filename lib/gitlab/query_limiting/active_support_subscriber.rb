# frozen_string_literal: true

module Gitlab
  module QueryLimiting
    class ActiveSupportSubscriber < ActiveSupport::Subscriber
      attach_to :active_record

      def sql(event)
        return if !::Gitlab::QueryLimiting::Transaction.current || event.payload.fetch(:cached, event.payload[:name] == 'CACHE')

        ::Gitlab::QueryLimiting::Transaction.current.increment(event.payload[:sql])
        ::Gitlab::QueryLimiting::Transaction.current.executed_sql(event.payload[:sql])
      end
    end
  end
end
