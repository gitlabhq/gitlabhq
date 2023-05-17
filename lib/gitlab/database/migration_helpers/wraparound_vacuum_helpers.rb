# frozen_string_literal: true

module Gitlab
  module Database
    module MigrationHelpers
      module WraparoundVacuumHelpers
        class WraparoundCheck
          WraparoundError = Class.new(StandardError)

          def initialize(table_name, migration:)
            @migration = migration
            @table_name = table_name

            validate_table_existence!
          end

          def execute
            return if disabled?
            return unless wraparound_vacuum.present?

            log "Autovacuum with wraparound prevention mode is running on `#{table_name}`", title: true
            log "This process prevents the migration from acquiring the necessary locks"
            log "Query: `#{wraparound_vacuum[:query]}`"
            log "Current duration: #{wraparound_vacuum[:duration].inspect}"
            log "You can wait until it completes or if absolutely necessary interrupt it, " \
                "but be aware that a new process will kick in immediately, so multiple interruptions " \
                "might be required to time it right with the locks retry mechanism"
          end

          private

          attr_reader :table_name

          delegate :say, :connection, to: :@migration

          def wraparound_vacuum
            @wraparound_vacuum ||= transform_wraparound_vacuum
          end

          def transform_wraparound_vacuum
            result = raw_wraparound_vacuum
            values = Array.wrap(result.cast_values.first)

            result.columns.zip(values).to_h.with_indifferent_access.compact
          end

          def raw_wraparound_vacuum
            connection.select_all(<<~SQL.squish)
              SELECT age(clock_timestamp(), query_start) as duration, query
                FROM postgres_pg_stat_activity_autovacuum()
                WHERE query ILIKE '%VACUUM%' || #{quoted_table_name} || '%(to prevent wraparound)'
                LIMIT 1
            SQL
          end

          def validate_table_existence!
            return if connection.table_exists?(table_name)

            raise WraparoundError, "Table #{table_name} does not exist"
          end

          def quoted_table_name
            connection.quote(table_name)
          end

          def disabled?
            return true unless wraparound_check_allowed?

            Gitlab::Utils.to_boolean(ENV['GITLAB_MIGRATIONS_DISABLE_WRAPAROUND_CHECK'])
          end

          def wraparound_check_allowed?
            Gitlab.com? || Gitlab.dev_or_test_env?
          end

          def log(text, title: false)
            say text, !title
          end
        end

        def check_if_wraparound_in_progress(table_name)
          WraparoundCheck.new(table_name, migration: self).execute
        end
      end
    end
  end
end
