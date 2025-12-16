# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    class BackfillSecurityProjectTrackedContextsDefaultBranch < BatchedMigrationJob
      operation_name :backfill_security_project_tracked_contexts_default_branch
      feature_category :vulnerability_management

      def perform
        each_sub_batch do |sub_batch|
          insert_default_branch_contexts(Project.id_in(sub_batch.pluck(:id)))
        end
      end

      private

      def insert_default_branch_contexts(projects)
        current_time = Time.current
        insert_attributes = projects.map do |project|
          {
            project_id: project.id,
            context_name: project.default_branch_or_main,
            context_type: SecurityProjectTrackedContext.context_types[:branch],
            state: SecurityProjectTrackedContext::STATES[:tracked],
            is_default: true,
            created_at: current_time,
            updated_at: current_time
          }
        end

        SecurityProjectTrackedContext.insert_all(insert_attributes)
      end

      class SecurityProjectTrackedContext < ::SecApplicationRecord
        STATES = { untracked: 1, tracked: 2, archiving: 0, deleting: -1 }.freeze

        self.table_name = 'security_project_tracked_contexts'

        enum :context_type, {
          branch: 1,
          tag: 2
        }
      end

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
          @commit_cache = {}
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
          class_name: '::Gitlab::BackgroundMigration::BackfillSecurityProjectTrackedContextsDefaultBranch::Namespace'
      end

      class Project < ::ApplicationRecord
        include Routable

        self.table_name = 'projects'

        belongs_to :namespace,
          class_name: '::Gitlab::BackgroundMigration::BackfillSecurityProjectTrackedContextsDefaultBranch::Namespace'
        alias_method :parent, :namespace

        has_one :route,
          as: :source,
          class_name: '::Gitlab::BackgroundMigration::BackfillSecurityProjectTrackedContextsDefaultBranch::Route'

        def default_branch
          @default_branch ||= repository.root_ref
        end

        def default_branch_or_main
          return default_branch if default_branch

          'main'
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
    end
  end
end
