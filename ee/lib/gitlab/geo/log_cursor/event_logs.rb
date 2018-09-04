module Gitlab
  module Geo
    module LogCursor
      # Manages events from primary database and store state in the DR database
      class EventLogs
        BATCH_SIZE = 50

        # fetches up to BATCH_SIZE next events and keep track of batches
        # rubocop: disable CodeReuse/ActiveRecord
        def fetch_in_batches(batch_size: BATCH_SIZE)
          last_id = last_processed_id

          ::Geo::EventLog.where('id > ?', last_id).find_in_batches(batch_size: batch_size) do |batch|
            yield(batch, last_id)

            last_id = batch.last.id
            save_processed(last_id)

            break unless Lease.renew!
          end
        end
        # rubocop: enable CodeReuse/ActiveRecord

        private

        # saves last replicated event
        def save_processed(event_id)
          event_state = ::Geo::EventLogState.last || ::Geo::EventLogState.new
          event_state.update!(event_id: event_id)
        end

        # @return [Integer] id of last replicated event
        def last_processed_id
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
