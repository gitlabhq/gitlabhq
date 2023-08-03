# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    # rubocop:disable Style/Documentation
    class BackfillProjectStatisticsStorageSizeWithoutPipelineArtifactsSizeJob < Gitlab::BackgroundMigration::BatchedMigrationJob # rubocop:disable Layout/LineLength
      class Project < ::ApplicationRecord
        self.table_name = 'projects'

        has_one :statistics, class_name: '::Gitlab::BackgroundMigration::BackfillProjectStatisticsStorageSizeWithoutPipelineArtifactsSizeJob::ProjectStatistics' # rubocop:disable Layout/LineLength
      end

      class ProjectStatistics < ::ApplicationRecord
        include ::EachBatch

        self.table_name = 'project_statistics'

        belongs_to :project, class_name: '::Gitlab::BackgroundMigration::BackfillProjectStatisticsStorageSizeWithoutPipelineArtifactsSizeJob::Project' # rubocop:disable Layout/LineLength

        def update_storage_size(storage_size_components)
          new_storage_size = storage_size_components.sum { |component| method(component).call }

          # Only update storage_size if storage_size needs updating
          return unless storage_size != new_storage_size

          self.storage_size = new_storage_size
          save!

          ::Namespaces::ScheduleAggregationWorker.perform_async(project.namespace_id)
          log_with_data('Scheduled Namespaces::ScheduleAggregationWorker')
        end

        def wiki_size
          super.to_i
        end

        def snippets_size
          super.to_i
        end

        private

        def log_with_data(log_line)
          log_info(
            log_line,
            project_id: project.id,
            pipeline_artifacts_size: pipeline_artifacts_size,
            storage_size: storage_size,
            namespace_id: project.namespace_id
          )
        end

        def log_info(message, **extra)
          ::Gitlab::BackgroundMigration::Logger.info(
            migrator: 'BackfillProjectStatisticsStorageSizeWithoutPipelineArtifactsSizeJob',
            message: message,
            **extra
          )
        end
      end

      scope_to ->(relation) {
        relation.where.not(pipeline_artifacts_size: 0)
      }
      operation_name :update_storage_size
      feature_category :consumables_cost_management

      def perform
        each_sub_batch do |sub_batch|
          ProjectStatistics.merge(sub_batch).each do |statistics|
            statistics.update_storage_size(storage_size_components)
          end
        end
      end

      private

      # Overridden in EE
      def storage_size_components
        [
          :repository_size,
          :wiki_size,
          :lfs_objects_size,
          :build_artifacts_size,
          :packages_size,
          :snippets_size,
          :uploads_size
        ]
      end
    end
    # rubocop:enable Style/Documentation
  end
end

Gitlab::BackgroundMigration::BackfillProjectStatisticsStorageSizeWithoutPipelineArtifactsSizeJob.prepend_mod
