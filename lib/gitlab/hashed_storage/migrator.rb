module Gitlab
  module HashedStorage
    # Hashed Storage Migrator
    #
    # This is responsible for scheduling and flagging projects
    # to be migrated from Legacy to Hashed storage, either one by one or in bulk.
    class Migrator
      BATCH_SIZE = 100

      # Schedule a range of projects to be bulk migrated with #bulk_migrate asynchronously
      #
      # @param [Object] start first project id for the range
      # @param [Object] finish last project id for the range
      def bulk_schedule(start, finish)
        StorageMigratorWorker.perform_async(start, finish)
      end

      # Start migration of projects from specified range
      #
      # Flagging a project to be migrated is a synchronous action,
      # but the migration runs through async jobs
      #
      # @param [Object] start first project id for the range
      # @param [Object] finish last project id for the range
      # rubocop: disable CodeReuse/ActiveRecord
      def bulk_migrate(start, finish)
        projects = build_relation(start, finish)

        projects.with_route.find_each(batch_size: BATCH_SIZE) do |project|
          migrate(project)
        end
      end
      # rubocop: enable CodeReuse/ActiveRecord

      # Flag a project to be migrated
      #
      # @param [Object] project that will be migrated
      def migrate(project)
        Rails.logger.info "Starting storage migration of #{project.full_path} (ID=#{project.id})..."

        project.migrate_to_hashed_storage!
      rescue => err
        Rails.logger.error("#{err.message} migrating storage of #{project.full_path} (ID=#{project.id}), trace - #{err.backtrace}")
      end

      private

      # rubocop: disable CodeReuse/ActiveRecord
      def build_relation(start, finish)
        relation = Project
        table = Project.arel_table

        relation = relation.where(table[:id].gteq(start)) if start
        relation = relation.where(table[:id].lteq(finish)) if finish

        relation
      end
      # rubocop: enable CodeReuse/ActiveRecord
    end
  end
end
