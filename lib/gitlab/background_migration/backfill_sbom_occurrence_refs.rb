# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    class BackfillSbomOccurrenceRefs < BatchedMigrationJob
      cursor :id

      operation_name :backfill_sbom_occurrence_refs
      feature_category :dependency_management

      # context_type enum: branch => 1 (see Security::ProjectTrackedContext)
      BRANCH_CONTEXT_TYPE = 1

      def perform
        each_sub_batch do |sub_batch|
          occurrences = sub_batch.pluck(:id, :project_id, :commit_sha, :pipeline_id)
          next if occurrences.empty?

          project_ids = occurrences.map { |_id, project_id, _sha, _pipeline| project_id }.uniq
          context_id_by_project = default_context_ids_by_project(project_ids)
          next if context_id_by_project.empty?

          rows = build_rows(occurrences, context_id_by_project)
          next if rows.empty?

          SbomOccurrenceRef.upsert_all(
            rows,
            unique_by: %i[sbom_occurrence_id security_project_tracked_context_id]
          )
        end
      end

      private

      # Returns { project_id => security_project_tracked_context_id }.
      #
      # For projects with a single default-branch context we use it directly
      # (no Gitaly). For projects with multiple default-branch contexts (caused
      # by an old bug) we resolve the real default branch via Gitaly and pick
      # the context whose context_name matches it, falling back to the lowest
      # id if none match.
      def default_context_ids_by_project(project_ids)
        contexts_by_project = SecurityProjectTrackedContext
          .default_branch_refs
          .where(project_id: project_ids)
          .order(:id)
          .pluck(:project_id, :id, :context_name)
          .group_by(&:first)

        result = {}

        single, multiple = contexts_by_project.partition { |_pid, rows| rows.size == 1 }

        single.each do |project_id, rows|
          result[project_id] = rows.first[1]
        end

        resolve_multiple_defaults(multiple, result)

        result
      end

      # multiple: array of [project_id, [[project_id, id, context_name], ...]]
      def resolve_multiple_defaults(multiple, result)
        return if multiple.empty?

        project_ids = multiple.map(&:first)
        projects_by_id = Project.where(id: project_ids).index_by(&:id)

        multiple.each do |project_id, rows|
          project = projects_by_id[project_id]
          default_branch = project&.default_branch

          matched = rows.find { |_pid, _id, name| name == default_branch } if default_branch

          # Deterministic fallback: lowest id (rows already ordered by id).
          chosen = matched || rows.first
          result[project_id] = chosen[1]
        end
      rescue StandardError => e
        ::Gitlab::BackgroundMigration::Logger.warn(
          message: 'Failed resolving default branch for projects with multiple default contexts',
          error_message: e.message,
          backtrace: e.backtrace&.first(20)
        )
        raise
      end

      def build_rows(occurrences, context_id_by_project)
        occurrences.filter_map do |occurrence_id, project_id, commit_sha, pipeline_id|
          context_id = context_id_by_project[project_id]
          next unless context_id

          {
            sbom_occurrence_id: occurrence_id,
            security_project_tracked_context_id: context_id,
            project_id: project_id,
            commit_sha: commit_sha,
            pipeline_id: pipeline_id
          }
        end
      end

      class SecurityProjectTrackedContext < ::SecApplicationRecord
        self.table_name = 'security_project_tracked_contexts'

        scope :default_branch_refs, -> do
          where(is_default: true, context_type: BRANCH_CONTEXT_TYPE)
        end
      end

      class SbomOccurrenceRef < ::SecApplicationRecord
        self.table_name = 'sbom_occurrence_refs'
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

      class Namespace < ::ApplicationRecord
        include Routable

        self.table_name = 'namespaces'
        self.inheritance_column = :_type_disabled

        belongs_to :parent,
          class_name: '::Gitlab::BackgroundMigration::BackfillSbomOccurrenceRefs::Namespace'
      end

      # Minimal Gitaly-backed repository wrapper, mirroring
      # RemoveDuplicateDefaultTrackedContexts. Used only to read the root ref
      # for projects that have multiple default-branch tracked contexts.
      class Repository
        def initialize(full_path, container, shard:, disk_path:)
          @full_path = full_path
          @shard = shard
          @disk_path = disk_path || full_path
          @container = container
        end

        def root_ref
          raw_repository&.root_ref
        rescue ::Gitlab::Git::Repository::NoRepository
          nil
        end

        private

        attr_reader :full_path, :shard, :disk_path, :container

        def raw_repository
          return unless full_path

          @raw_repository ||= ::Gitlab::Git::Repository.new(
            shard,
            "#{disk_path}.git",
            ::Gitlab::GlRepository::PROJECT.identifier_for_container(container),
            container.full_path,
            container: container
          )
        end
      end

      module Storage
        class Hashed
          REPOSITORY_PATH_PREFIX = '@hashed'

          attr_accessor :container

          def initialize(container)
            @container = container
          end

          def disk_path
            "#{base_dir}/#{disk_hash}" if disk_hash
          end

          private

          def base_dir
            "#{REPOSITORY_PATH_PREFIX}/#{disk_hash[0..1]}/#{disk_hash[2..3]}" if disk_hash
          end

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

      class Project < ::ApplicationRecord
        include Routable

        self.table_name = 'projects'

        belongs_to :namespace,
          class_name: '::Gitlab::BackgroundMigration::BackfillSbomOccurrenceRefs::Namespace'
        alias_method :parent, :namespace

        has_one :route,
          as: :source,
          class_name: '::Gitlab::BackgroundMigration::BackfillSbomOccurrenceRefs::Route'

        def default_branch
          @default_branch ||= repository.root_ref
        end

        def repository
          @repository ||= Repository.new(
            full_path, self, shard: repository_storage, disk_path: storage.disk_path
          )
        end

        private

        def storage
          @storage ||=
            if storage_version.to_i >= 1
              Storage::Hashed.new(self)
            else
              Storage::LegacyProject.new(self)
            end
        end
      end
    end
  end
end
