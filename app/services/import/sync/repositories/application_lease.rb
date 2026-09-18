# frozen_string_literal: true

module Import
  module Sync
    module Repositories
      # Makes sure only one job at a time syncs a given repository, using a
      # Redis lock.
      #
      # This lock alone does not stop a double-write: the row lock and
      # generation-counter check each sync step does against
      # `application_generation` is what actually prevents that.
      class ApplicationLease
        include Gitlab::ExclusiveLeaseHelpers

        LEASE_TTL = 5.minutes

        LostLeaseError = Class.new(StandardError)

        # Lets callers check they still hold the lock, without exposing its UUID.
        class Context
          def initialize(lease, repository_id)
            @lease = lease
            @repository_id = repository_id
          end

          def verify!
            return true if @lease.same_uuid?

            raise LostLeaseError, 'Import sync repository application lease was lost'
          end

          def verify_repository!(expected_repository_id)
            verify!
            return true if @repository_id == expected_repository_id

            raise LostLeaseError, 'Import sync repository application lease does not match the repository'
          end

          # Extends the lock for another LEASE_TTL. Callers renew after every
          # round trip to GitHub or Gitaly.
          def renew!
            return true if @lease.renew

            raise LostLeaseError, 'Import sync repository application lease was lost'
          end
        end

        def self.key(repository_id)
          "import_sync:repository:#{repository_id}:application"
        end

        def initialize(repository_id, retries: 0, sleep_sec: 1.second)
          @repository_id = repository_id
          @retries = retries
          @sleep_sec = sleep_sec
        end

        # Runs the block while holding the lock for this repository.
        # If the lock can't be obtained, raises FailedToObtainLockError and
        # never runs the block.
        def execute
          in_lock(
            self.class.key(repository_id),
            ttl: LEASE_TTL,
            retries: retries,
            sleep_sec: sleep_sec
          ) do |_retried, lease|
            context = Context.new(lease, repository_id)
            result = yield(context)
            context.verify!
            result
          end
        end

        private

        attr_reader :repository_id, :retries, :sleep_sec
      end
    end
  end
end
