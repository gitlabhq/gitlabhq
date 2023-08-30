# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    # rubocop:disable Style/Documentation
    class BackfillProjectStatisticsStorageSizeWithRecentSize < BatchedMigrationJob
      RECENT_OBJECTS_SIZE_ENABLED_AT = Date.new(2023, 8, 8).freeze

      class Route < ::ApplicationRecord
        belongs_to :source, inverse_of: :route, polymorphic: true
      end

      class Namespace < ::ApplicationRecord
        self.table_name = 'namespaces'
        self.inheritance_column = nil # rubocop:disable Database/AvoidInheritanceColumn

        include Routable

        belongs_to :parent, class_name: 'Namespace', inverse_of: 'namespaces'

        has_one :route, -> { where(source_type: 'Namespace') }, inverse_of: :source, foreign_key: :source_id

        has_many :projects, inverse_of: :parent
        has_many :namespaces, inverse_of: :parent
      end

      class Project < ::ApplicationRecord
        self.table_name = 'projects'

        include Routable

        has_one :statistics, class_name: '::Gitlab::BackgroundMigration::BackfillProjectStatisticsStorageSizeWithRecentSize::ProjectStatistics' # rubocop:disable Layout/LineLength
        has_one :route, -> { where(source_type: 'Project') }, inverse_of: :source, foreign_key: :source_id
        belongs_to :parent, class_name: 'Namespace', foreign_key: :namespace_id, inverse_of: 'projects'

        delegate :disk_path, to: :storage

        def repository
          Gitlab::GlRepository::PROJECT.repository_for(self)
        end

        def storage
          Storage::Hashed.new(self)
        end
      end

      module Storage
        class Hashed
          attr_accessor :project

          ROOT_PATH_PREFIX = '@hashed'

          def initialize(project)
            @project = project
          end

          def disk_path
            "#{ROOT_PATH_PREFIX}/#{disk_hash[0..1]}/#{disk_hash[2..3]}/#{disk_hash}"
          end

          def disk_hash
            @disk_hash ||= Digest::SHA2.hexdigest(project.id.to_s)
          end
        end
      end

      class ProjectStatistics < ::ApplicationRecord
        include ::EachBatch

        self.table_name = 'project_statistics'

        belongs_to :project, class_name: '::Gitlab::BackgroundMigration::BackfillProjectStatisticsStorageSizeWithRecentSize::Project' # rubocop:disable Layout/LineLength

        def update_repository_size
          self.repository_size = project.repository.recent_objects_size.megabytes
        end

        def update_storage_size(storage_size_components)
          return unless repository_size > 0

          update_repository_size

          new_storage_size = storage_size_components.sum { |component| method(component).call }

          # Only update storage_size if storage_size needs updating
          return unless storage_size != new_storage_size

          self.storage_size = new_storage_size
          save!

          ::Namespaces::ScheduleAggregationWorker.perform_async(project.namespace_id)
          log_with_data('Scheduled Namespaces::ScheduleAggregationWorker')
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
            migrator: 'BackfillProjectStatisticsStorageSizeWithRecentSize',
            message: message,
            **extra
          )
        end

        def wiki_size
          super.to_i
        end

        def snippets_size
          super.to_i
        end
      end

      scope_to ->(relation) do
        scope = relation.where('repository_size > 0')

        if Gitlab.dev_or_test_env? || Gitlab.org_or_com?
          scope = scope.where('updated_at < ?', RECENT_OBJECTS_SIZE_ENABLED_AT)
        end

        scope
      end

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
  end
  # rubocop:enable Style/Documentation
end

Gitlab::BackgroundMigration::BackfillProjectStatisticsStorageSizeWithRecentSize.prepend_mod
