# frozen_string_literal: true

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
      # @param [Integer] start first project id for the range
      # @param [Integer] finish last project id for the range
      def bulk_schedule_migration(start:, finish:)
        ::HashedStorage::MigratorWorker.perform_async(start, finish)
      end

      # Schedule a range of projects to be bulk rolledback with #bulk_rollback asynchronously
      #
      # @param [Integer] start first project id for the range
      # @param [Integer] finish last project id for the range
      def bulk_schedule_rollback(start:, finish:)
        ::HashedStorage::RollbackerWorker.perform_async(start, finish)
      end

      # Start migration of projects from specified range
      #
      # Flagging a project to be migrated is a synchronous action
      # but the migration runs through async jobs
      #
      # @param [Integer] start first project id for the range
      # @param [Integer] finish last project id for the range
      # rubocop: disable CodeReuse/ActiveRecord
      def bulk_migrate(start:, finish:)
        projects = build_relation(start, finish)

        projects.with_route.find_each(batch_size: BATCH_SIZE) do |project|
          migrate(project)
        end
      end
      # rubocop: enable CodeReuse/ActiveRecord

      # Start rollback of projects from specified range
      #
      # Flagging a project to be rolled back is a synchronous action
      # but the rollback runs through async jobs
      #
      # @param [Integer] start first project id for the range
      # @param [Integer] finish last project id for the range
      # rubocop: disable CodeReuse/ActiveRecord
      def bulk_rollback(start:, finish:)
        projects = build_relation(start, finish)

        projects.with_route.find_each(batch_size: BATCH_SIZE) do |project|
          rollback(project)
        end
      end
      # rubocop: enable CodeReuse/ActiveRecord

      # Flag a project to be migrated to Hashed Storage
      #
      # @param [Project] project that will be migrated
      def migrate(project)
        Gitlab::AppLogger.info "Starting storage migration of #{project.full_path} (ID=#{project.id})..."

        project.migrate_to_hashed_storage!
      rescue StandardError => err
        Gitlab::AppLogger.error("#{err.message} migrating storage of #{project.full_path} (ID=#{project.id}), trace - #{err.backtrace}")
      end

      # Flag a project to be rolled-back to Legacy Storage
      #
      # @param [Project] project that will be rolled-back
      def rollback(project)
        Gitlab::AppLogger.info "Starting storage rollback of #{project.full_path} (ID=#{project.id})..."

        project.rollback_to_legacy_storage!
      rescue StandardError => err
        Gitlab::AppLogger.error("#{err.message} rolling-back storage of #{project.full_path} (ID=#{project.id}), trace - #{err.backtrace}")
      end

      # Returns whether we have any pending storage migration
      #
      def migration_pending?
        any_non_empty_queue?(::HashedStorage::MigratorWorker, ::HashedStorage::ProjectMigrateWorker)
      end

      # Returns whether we have any pending storage rollback
      #
      def rollback_pending?
        any_non_empty_queue?(::HashedStorage::RollbackerWorker, ::HashedStorage::ProjectRollbackWorker)
      end

      # Remove all remaining scheduled rollback operations
      #
      def abort_rollback!
        [::HashedStorage::RollbackerWorker, ::HashedStorage::ProjectRollbackWorker].each do |worker|
          Sidekiq::Queue.new(worker.queue).clear
        end
      end

      private

      def any_non_empty_queue?(*workers)
        workers.any? do |worker|
          Sidekiq::Queue.new(worker.queue).size != 0 # rubocop:disable Style/ZeroLengthPredicate
        end
      end

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
