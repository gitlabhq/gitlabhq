# frozen_string_literal: true

module Gitlab
  module Database
    module BackgroundMigration
      module HealthStatus
        # Rather than passing along the migration, we use a more explicitly defined context
        Context = Struct.new(:tables)

        def self.evaluate(migration, indicator = Indicators::AutovacuumActiveOnTable)
          signal = begin
            indicator.new(migration.health_context).evaluate
          rescue StandardError => e
            Gitlab::ErrorTracking.track_exception(e, migration_id: migration.id,
                                                  job_class_name: migration.job_class_name)
            Signals::Unknown.new(indicator, reason: "unexpected error: #{e.message} (#{e.class})")
          end

          log_signal(signal, migration) if signal.log_info?

          signal
        end

        def self.log_signal(signal, migration)
          Gitlab::AppLogger.info(
            message: "#{migration} signaled: #{signal}",
            migration_id: migration.id
          )
        end
      end
    end
  end
end
