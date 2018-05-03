module Gitlab
  module Geo
    module LogCursor
      module Lease
        NAMESPACE = 'geo:gitlab'.freeze
        LEASE_TIMEOUT = 30.seconds.freeze
        LEASE_KEY = 'geo_log_cursor_processed'.freeze

        def self.exclusive_lease
          @lease ||= Gitlab::ExclusiveLease.new(LEASE_KEY, timeout: LEASE_TIMEOUT)
        end

        def self.renew!
          lease = exclusive_lease.renew

          logger.debug lease ? 'Lease renewed.' : 'Lease not renewed.'

          { uuid: lease, ttl: lease ? 0 : LEASE_TIMEOUT }
        end

        def self.try_obtain_with_ttl
          lease = exclusive_lease.try_obtain_with_ttl

          unless lease[:ttl].zero? || exclusive_lease.same_uuid?
            $stdout.puts lease_taken_message
            logger.info(lease_taken_message)

            return lease
          end

          begin
            logger.debug('Lease obtained. Fetching events.')

            yield

            logger.debug('Finished fetching events.')

            renew!
          rescue => e
            logger.error("Lease canceled due to error: #{e.message}")

            Gitlab::ExclusiveLease.cancel(LEASE_KEY, lease[:uuid])

            { uuid: false, ttl: LEASE_TIMEOUT }
          end
        end

        def self.lease_taken_message
          'Cannot obtain an exclusive lease. There must be another process already in execution.'
        end

        def self.logger
          @logger ||= Gitlab::Geo::LogCursor::Logger.new(self)
        end

        private_class_method :exclusive_lease, :lease_taken_message, :logger
      end
    end
  end
end
