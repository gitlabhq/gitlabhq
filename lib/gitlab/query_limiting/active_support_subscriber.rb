module Gitlab
  module QueryLimiting
    class ActiveSupportSubscriber < ActiveSupport::Subscriber
      attach_to :active_record

      def sql(event)
        unless event.payload[:name] == 'CACHE' || rails_schema_load?(event.payload[:sql])
          Transaction.current&.increment
        end
      end

      # Rails will attempt to load the table schema the first time it accesses
      # it. This can push specs over the query limit, and the application
      # can't do anything about it (aside from avoiding column_exists? or
      # table_exists? calls).
      def rails_schema_load?(sql)
        # Can't use Gitlab::Database.postgresql? since this may break test expectations
        sql.match(/SELECT.*FROM pg_attribute /m)
      end
    end
  end
end
