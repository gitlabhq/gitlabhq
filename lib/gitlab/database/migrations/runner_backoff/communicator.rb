# frozen_string_literal: true

module Gitlab
  module Database
    module Migrations
      module RunnerBackoff
        class Communicator
          EXPIRY = 1.minute
          KEY = 'gitlab/database/migration/runner/backoff'

          def self.execute_with_lock(migration, &block)
            new(migration).execute_with_lock(&block)
          end

          def self.backoff_runner?
            return false if ::Feature.disabled?(:runner_migrations_backoff, type: :ops)

            Gitlab::ExclusiveLease.new(KEY, timeout: EXPIRY).exists?
          end

          def initialize(migration, logger: Gitlab::AppLogger)
            @migration = migration
            @logger = logger
          end

          def execute_with_lock
            log(message: 'Executing migration with Runner backoff')

            set_lock
            yield if block_given?
          ensure
            remove_lock
          end

          private

          attr_reader :logger, :migration

          def set_lock
            raise 'Could not set backoff key' unless exclusive_lease.try_obtain

            log(message: 'Runner backoff key is set')
          end

          def remove_lock
            exclusive_lease.cancel

            log(message: 'Runner backoff key was removed')
          end

          def exclusive_lease
            @exclusive_lease ||= Gitlab::ExclusiveLease.new(KEY, timeout: EXPIRY)
          end

          def log(params)
            logger.info(log_params.merge(params))
          end

          def log_params
            { class: migration.name }
          end
        end
      end
    end
  end
end
