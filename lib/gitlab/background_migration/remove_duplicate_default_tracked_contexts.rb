# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    class RemoveDuplicateDefaultTrackedContexts < BatchedMigrationJob
      operation_name :remove_duplicate_default_tracked_contexts
      feature_category :vulnerability_management

      module Storage
        class Hashed
          attr_accessor :container

          REPOSITORY_PATH_PREFIX = '@hashed'

          def initialize(container)
            @container = container
          end

          def base_dir
            "#{REPOSITORY_PATH_PREFIX}/#{disk_hash[0..1]}/#{disk_hash[2..3]}" if disk_hash
          end

          def disk_path
            "#{base_dir}/#{disk_hash}" if disk_hash
          end

          private

          def disk_hash
            @disk_hash ||= Digest::SHA2.hexdigest(container.id.to_s) if container.id
          end
        end

        class LegacyProject
          attr_accessor :project

          def initialize(project)
            @project = project
          end

          def disk_path
            project.full_path
          end
        end
      end

      module Routable
        extend ActiveSupport::Concern

        included do
          has_one :route, as: :source
        end

        def full_path
          route&.path || build_full_path
        end

        def build_full_path
          if parent && path
            "#{parent.full_path}/#{path}"
          else
            path
          end
        end
      end

      class Route < ::ApplicationRecord
        self.table_name = 'routes'
      end

      # This class depends on following classes
      #   GlRepository class defined in `lib/gitlab/gl_repository.rb`
      #   Repository class defined in `lib/gitlab/git/repository.rb`.
      class Repository
        FORMAT_SHA256 = 'sha256'

        def initialize(full_path, container, shard:, disk_path: nil, repo_type: ::Gitlab::GlRepository::PROJECT)
          @full_path = full_path
          @shard = shard
          @disk_path = disk_path || full_path
          @container = container
          @repo_type = repo_type
        end

        def create_repository(default_branch)
          raw_repository.create_repository(default_branch, object_format: FORMAT_SHA256)
        end

        def root_ref
          raw_repository&.root_ref
        rescue ::Gitlab::Git::Repository::NoRepository
        end

        def exists?
          return false unless full_path

          raw_repository.exists?
        end

        def create_file_actions(path, content)
          [{ action: :create, file_path: path, content: content }]
        end

        def create_file(user, path, content, **options)
          actions = create_file_actions(path, content)
          commit_files(user, **options.merge(actions: actions))
        end

        def commit_files(user, **options)
          raw_repository.commit_files(user, **options.merge(sign: false))
        end

        private

        attr_reader :full_path, :shard, :disk_path, :container, :repo_type

        def raw_repository
          return unless full_path

          @raw_repository ||= initialize_raw_repository
        end

        def initialize_raw_repository
          ::Gitlab::Git::Repository.new(
            shard,
            "#{disk_path}.git",
            repo_type.identifier_for_container(container),
            container.full_path,
            container: container
          )
        end
      end

      class Namespace < ::ApplicationRecord
        include Routable

        self.table_name = 'namespaces'
        self.inheritance_column = :_type_disabled

        belongs_to :parent,
          class_name: '::Gitlab::BackgroundMigration::RemoveDuplicateDefaultTrackedContexts::Namespace'
      end

      class Project < ::ApplicationRecord
        include Routable

        self.table_name = 'projects'

        belongs_to :namespace,
          class_name: '::Gitlab::BackgroundMigration::RemoveDuplicateDefaultTrackedContexts::Namespace'
        alias_method :parent, :namespace

        has_one :route,
          as: :source,
          class_name: '::Gitlab::BackgroundMigration::RemoveDuplicateDefaultTrackedContexts::Route'

        def default_branch
          @default_branch ||= repository.root_ref
        end

        def create_repository(default_branch)
          repository.create_repository(default_branch)
        end

        def repository
          @repository ||= Repository.new(full_path, self, shard: repository_storage, disk_path: storage.disk_path)
        end

        private

        def storage
          @storage ||=
            if hashed_repository_storage?
              Storage::Hashed.new(self)
            else
              Storage::LegacyProject.new(self)
            end
        end

        def hashed_repository_storage?
          storage_version.to_i >= 1
        end
      end

      class VulnerabilityOccurrence < ::SecApplicationRecord
        include EachBatch

        self.table_name = 'vulnerability_occurrences'
      end

      class VulnerabilityRead < ::SecApplicationRecord
        include EachBatch

        self.table_name = 'vulnerability_reads'
      end

      class SbomOccurrenceRefs < ::SecApplicationRecord
        include EachBatch

        self.table_name = 'sbom_occurrence_refs'
      end

      class VulnerabilityStatistic < ::SecApplicationRecord
        self.table_name = 'vulnerability_statistics'
      end

      class VulnerabilityHistoricalStatistic < ::SecApplicationRecord
        self.table_name = 'vulnerability_historical_statistics'
      end

      class SecurityProjectTrackedContext < ::SecApplicationRecord
        self.table_name = 'security_project_tracked_contexts'

        scope :default_refs, -> { where(is_default: true) }
      end

      LARGE_TABLES = [VulnerabilityOccurrence, VulnerabilityRead].freeze
      SMALL_TABLES = [VulnerabilityStatistic, VulnerabilityHistoricalStatistic].freeze
      BRANCH_CONTEXT_TYPE = 1

      def perform
        each_sub_batch do |sub_batch|
          projects = projects_with_multiple_contexts(sub_batch)
          all_contexts = SecurityProjectTrackedContext.where(project_id: projects.map(&:id), is_default: true)

          default_branches = projects.each_with_object({}) do |project, result|
            result[project.id] = project.default_branch
          end

          update_associated_records(default_branches, all_contexts)
          remove_invalid_contexts(invalid_context_ids(default_branches, all_contexts))
        end
      end

      private

      def projects_with_multiple_contexts(sub_batch)
        project_ids = SecurityProjectTrackedContext
                        .where(project_id: sub_batch.pluck(:id))
                        .default_refs
                        .group(:project_id)
                        .having('COUNT(*) > 1')
                        .pluck(:project_id)

        Project.where(id: project_ids)
      end

      def remove_invalid_contexts(invalid_context_ids)
        return if invalid_context_ids.empty?

        SecurityProjectTrackedContext.id_in(invalid_context_ids).delete_all
      rescue StandardError => e
        ::Gitlab::BackgroundMigration::Logger.warn(
          message: "Duplicate tracked context deletion failed",
          error_message: e.message,
          backtrace: e.backtrace&.first(20)
        )
        raise
      end

      def invalid_context_ids(default_branches, contexts)
        contexts.select do |context|
          context.context_name != default_branches[context.project_id] && context.context_type == BRANCH_CONTEXT_TYPE
        end
      end

      def update_associated_records(default_branches, all_contexts)
        contexts_by_project = all_contexts.group_by(&:project_id)

        default_branches.each_pair do |project_id, default_branch|
          default_context = contexts_by_project[project_id]&.find do |context|
            context.context_name == default_branch && context.context_type == BRANCH_CONTEXT_TYPE
          end

          next unless default_context

          delete_sbom_occurrences(project_id, default_context)
          update_tables(project_id, default_context)
        end
      end

      def delete_sbom_occurrences(project_id, default_context)
        SbomOccurrenceRefs
          .where(project_id: project_id)
          .where.not(security_project_tracked_context_id: default_context.id)
          .each_batch do |relation|
            relation.delete_all
          end
      end

      def update_tables(project_id, default_context)
        LARGE_TABLES.each do |table|
          table
            .where(project_id: project_id)
            .where.not(security_project_tracked_context_id: default_context.id)
            .each_batch do |relation|
              relation.update_all(security_project_tracked_context_id: default_context.id)
            end
        end

        SMALL_TABLES.each do |table|
          table
            .where(project_id: project_id)
            .where.not(security_project_tracked_context_id: default_context.id)
            .update_all(security_project_tracked_context_id: default_context.id)
        end
      end
    end
  end
end
