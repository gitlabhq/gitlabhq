# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    class PruneOrphanedGeoEvents
      BATCH_SIZE = 50_000
      RESCHEDULE_DELAY = 5.minutes

      EVENT_TABLES = %w[geo_repository_created_events
                        geo_repository_updated_events
                        geo_repository_deleted_events
                        geo_repository_renamed_events
                        geo_repositories_changed_events
                        geo_hashed_storage_migrated_events
                        geo_hashed_storage_attachments_events
                        geo_lfs_object_deleted_events
                        geo_job_artifact_deleted_events
                        geo_upload_deleted_events].freeze

      module PrunableEvent
        extend ActiveSupport::Concern
        include EachBatch

        included do
          scope :orphans, -> do
            where(<<-SQL.squish)
              NOT EXISTS (
                SELECT 1
                FROM geo_event_log
                WHERE geo_event_log.#{geo_event_foreign_key} = #{table_name}.id
              )
              SQL
          end
        end

        class_methods do
          def geo_event_foreign_key
            table_name.singularize.sub(/^geo_/, '') + '_id'
          end

          def delete_batch_of_orphans!
            deleted = where(id: orphans.limit(BATCH_SIZE)).delete_all

            vacuum! if deleted.positive?

            deleted
          end

          def vacuum!
            connection.execute("VACUUM #{table_name}")
          rescue ActiveRecord::StatementInvalid => e
            # ignore timeout, auto-vacuum will take care of it
            raise unless e.message =~ /statement timeout/i
          end
        end
      end

      def perform(table_name = EVENT_TABLES.first)
        deleted = prune_orphaned_rows(table_name)

        table_name = next_table(table_name) if deleted.zero?

        BackgroundMigrationWorker.perform_in(RESCHEDULE_DELAY, self.class.name, table_name) if table_name
      end

      def prune_orphaned_rows(table)
        event_model(table).delete_batch_of_orphans!
      end

      def event_model(table)
        Class.new(ActiveRecord::Base) do
          include PrunableEvent

          self.table_name = table
        end
      end

      def next_table(table_name)
        return nil if EVENT_TABLES.last == table_name

        index = EVENT_TABLES.index(table_name)

        return nil unless index

        EVENT_TABLES[index + 1]
      end
    end
  end
end
