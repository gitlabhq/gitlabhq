module Gitlab
  module Geo
    module LogCursor
      # Manages events from primary database and store state in the DR database
      class EventLogs
        BATCH_SIZE = 50

        # fetches up to BATCH_SIZE next events and keep track of batches
        def fetch_in_batches(batch_size: BATCH_SIZE)
          ::Geo::EventLog.where('id > ?', last_processed).find_in_batches(batch_size: batch_size) do |batch|
            yield batch
            save_processed(batch.last.id)
            break unless Lease.renew!
          end
        end

        private

        # saves last replicated event
        def save_processed(event_id)
          event_state = ::Geo::EventLogState.last || ::Geo::EventLogState.new
          event_state.update!(event_id: event_id)
        end

        # @return [Integer] id of last replicated event
        def last_processed
          last = ::Geo::EventLogState.last_processed&.id
          return last if last

          if ::Geo::EventLog.any?
            event_id = ::Geo::EventLog.last.id
            save_processed(event_id)
            event_id
          else
            -1
          end
        end
      end
    end
  end
end
