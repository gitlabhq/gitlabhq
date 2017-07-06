module Gitlab
  module Geo
    module LogCursor
      # Manages events from primary database and store state in the DR database
      class Events
        BATCH_SIZE = 50
        NAMESPACE = 'geo:gitlab'.freeze
        LEASE_TIMEOUT = 5.minutes.freeze
        LEASE_KEY = 'geo_log_cursor_processed'.freeze

        # fetches up to BATCH_SIZE next events and keep track of batches
        def self.fetch_in_batches
          try_obtain_lease do
            ::Geo::EventLog.where('id > ?', last_processed).find_in_batches(batch_size: BATCH_SIZE) do |batch|
              yield batch

              save_processed(batch.last.id)
              break unless renew_lease!
            end
          end
        end

        # saves last replicated event
        def self.save_processed(event_id)
          event_state = ::Geo::EventLogState.last || ::Geo::EventLogState.new
          event_state.update!(event_id: event_id)
        end

        # @return [Integer] id of last replicated event
        def self.last_processed
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

        # private methods

        def self.try_obtain_lease
          lease = exclusive_lease.try_obtain

          unless lease
            $stdout.puts 'Cannot obtain an exclusive lease. There must be another process already in execution.'
            return
          end

          begin
            yield lease
          ensure
            Gitlab::ExclusiveLease.cancel(LEASE_KEY, lease)
          end
        end

        def self.renew_lease!
          exclusive_lease.renew
        end

        def self.exclusive_lease
          @lease ||= Gitlab::ExclusiveLease.new(LEASE_KEY, timeout: LEASE_TIMEOUT)
        end

        private_class_method :try_obtain_lease, :exclusive_lease
      end
    end
  end
end
