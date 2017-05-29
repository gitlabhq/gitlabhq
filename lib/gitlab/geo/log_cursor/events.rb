module Gitlab
  module Geo
    module LogCursor
      # Manages events from primary database and store state in the DR database
      class Events
        BATCH_SIZE = 50
        NAMESPACE = 'geo:gitlab'.freeze

        # fetches up to BATCH_SIZE next events and keep track of batches
        def self.fetch_in_batches
          ::Geo::EventLog.where('id > ?', last_processed).find_in_batches(batch_size: BATCH_SIZE) do |batch|
            yield batch
            save_processed(batch.last.id)
          end
        end

        # saves last replicated event
        def self.save_processed(event_id)
          ::Geo::EventLogState.create!(event_id: event_id)
          ::Geo::EventLogState.where('event_id < ?', event_id).delete_all
        end

        # @return [Integer] id of last replicated event
        def self.last_processed
          last = ::Geo::EventLogState.last_processed.try(:id)
          return last if last

          ::Geo::EventLog.any? ? ::Geo::EventLog.last.id : -1
        end
      end
    end
  end
end
