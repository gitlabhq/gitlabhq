module Gitlab
  module Geo
    module LogCursor
      class Daemon
        include Utils::StrongMemoize

        VERSION = '0.2.0'.freeze
        BATCH_SIZE = 250
        SECONDARY_CHECK_INTERVAL = 1.minute

        attr_reader :options

        def initialize(options = {})
          @options = options
          @exit = false
        end

        def run!
          trap_signals

          until exit?
            # Prevent the node from processing events unless it's a secondary
            unless Geo.secondary?
              sleep(SECONDARY_CHECK_INTERVAL)
              next
            end

            lease = Lease.try_obtain_with_ttl { run_once! }
            return if exit?

            # When no new event is found sleep for a few moments
            arbitrary_sleep(lease[:ttl])
          end
        end

        def run_once!
          # Wrap this with the connection to make it possible to reconnect if
          # PGbouncer dies: https://github.com/rails/rails/issues/29189
          ActiveRecord::Base.connection_pool.with_connection do
            LogCursor::EventLogs.new.fetch_in_batches { |batch| handle_events(batch) }
          end
        end

        private

        def handle_events(batch)
          batch.each do |event_log|
            next unless can_replay?(event_log)

            begin
              event = event_log.event
              event_klass_for(event).new(event, event_log.created_at, logger).process
            rescue NoMethodError => e
              logger.error(e.message)
              raise e
            end
          end
        end

        def event_klass_for(event)
          event_klass_name = event.class.name.demodulize
          current_namespace = self.class.name.deconstantize
          Object.const_get("#{current_namespace}::Events::#{event_klass_name}")
        end

        def trap_signals
          trap(:TERM) { quit! }
          trap(:INT) { quit! }
        end

        # Safe shutdown
        def quit!
          $stdout.puts 'Exiting...'

          @exit = true
        end

        def exit?
          @exit
        end

        def can_replay?(event_log)
          return true if event_log.project_id.nil?

          # Always replay events for deleted projects
          return true unless Project.exists?(event_log.project_id)

          Gitlab::Geo.current_node&.projects_include?(event_log.project_id)
        end

        # Sleeps for the expired TTL that remains on the lease plus some random seconds.
        #
        # This allows multiple GeoLogCursors to randomly process a batch of events,
        # without favouring the shortest path (or latency).
        def arbitrary_sleep(delay)
          sleep(delay + rand(1..20) * 0.1)
        end

        def logger
          strong_memoize(:logger) do
            Gitlab::Geo::LogCursor::Logger.new(self.class, log_level)
          end
        end

        def log_level
          options[:debug] ? :debug : Rails.logger.level
        end
      end
    end
  end
end
