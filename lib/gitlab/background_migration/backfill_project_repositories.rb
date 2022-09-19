# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    # Class that will create fill the project_repositories table
    # for projects an entry is is missing in this table.
    class BackfillProjectRepositories
      OrphanedNamespaceError = Class.new(StandardError)

      # Shard model
      class Shard < ActiveRecord::Base
        self.table_name = 'shards'
      end

      # Class that will find or create the shard by name.
      # There is only a small set of shards, which would
      # not change quickly, so look them up from memory
      # instead of hitting the DB each time.
      class ShardFinder
        def find_shard_id(name)
          shard_id = shards.fetch(name, nil)
          return shard_id if shard_id.present?

          Shard.transaction(requires_new: true) do # rubocop:disable Performance/ActiveRecordSubtransactions
            create!(name)
          end
        rescue ActiveRecord::RecordNotUnique
          reload!
          retry
        end

        private

        def create!(name)
          Shard.create!(name: name).tap { |shard| @shards[name] = shard.id }
        end

        def shards
          @shards ||= reload!
        end

        def reload!
          @shards = Hash[*Shard.all.flat_map { |shard| [shard.name, shard.id] }]
        end
      end

      module Storage
        # Class that returns the disk path for a project using hashed storage
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

        # Class that returns the disk path for a project using legacy storage
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

      # Concern used by Project and Namespace to determine the full route to the project
      module Routable
        extend ActiveSupport::Concern

        def full_path
          route&.path || build_full_path
        end

        def build_full_path
          return path unless has_parent?

          raise OrphanedNamespaceError if parent.nil?

          parent.full_path + '/' + path
        end

        def has_parent?
          read_attribute(association(:parent).reflection.foreign_key)
        end
      end

      # Route model
      class Route < ActiveRecord::Base
        belongs_to :source, inverse_of: :route, polymorphic: true
      end

      # Namespace model
      class Namespace < ActiveRecord::Base
        self.table_name = 'namespaces'
        self.inheritance_column = nil

        include Routable

        belongs_to :parent, class_name: 'Namespace', inverse_of: 'namespaces'

        has_one :route, -> { where(source_type: 'Namespace') }, inverse_of: :source, foreign_key: :source_id

        has_many :projects, inverse_of: :parent
        has_many :namespaces, inverse_of: :parent
      end

      # ProjectRegistry model
      class ProjectRepository < ActiveRecord::Base
        self.table_name = 'project_repositories'

        belongs_to :project, inverse_of: :project_repository
      end

      # Project model
      class Project < ActiveRecord::Base
        self.table_name = 'projects'

        include Routable

        HASHED_STORAGE_FEATURES = {
          repository: 1,
          attachments: 2
        }.freeze

        scope :with_parent, -> { includes(:parent) }

        belongs_to :parent, class_name: 'Namespace', foreign_key: :namespace_id, inverse_of: 'projects'

        has_one :route, -> { where(source_type: 'Project') }, inverse_of: :source, foreign_key: :source_id
        has_one :project_repository, inverse_of: :project

        delegate :disk_path, to: :storage

        class << self
          def on_hashed_storage
            where(Project.arel_table[:storage_version]
              .gteq(HASHED_STORAGE_FEATURES[:repository]))
          end

          def on_legacy_storage
            where(Project.arel_table[:storage_version].eq(nil)
              .or(Project.arel_table[:storage_version].eq(0)))
          end

          def without_project_repository
            joins(left_outer_join_project_repository)
              .where(ProjectRepository.arel_table[:project_id].eq(nil))
          end

          def left_outer_join_project_repository
            projects_table = Project.arel_table
            repository_table = ProjectRepository.arel_table

            projects_table
              .join(repository_table, Arel::Nodes::OuterJoin)
              .on(projects_table[:id].eq(repository_table[:project_id]))
              .join_sources
          end
        end

        def storage
          @storage ||=
            if hashed_storage?
              Storage::Hashed.new(self)
            else
              Storage::LegacyProject.new(self)
            end
        end

        def hashed_storage?
          self.storage_version &&
            self.storage_version >= HASHED_STORAGE_FEATURES[:repository]
        end
      end

      def perform(start_id, stop_id)
        ApplicationRecord.legacy_bulk_insert(:project_repositories, project_repositories(start_id, stop_id)) # rubocop:disable Gitlab/BulkInsert
      end

      private

      def projects
        raise NotImplementedError,
          "#{self.class} does not implement #{__method__}"
      end

      def project_repositories(start_id, stop_id)
        projects
          .without_project_repository
          .includes(:route, parent: [:route]).references(:routes)
          .includes(:parent).references(:namespaces)
          .where(id: start_id..stop_id)
          .map { |project| build_attributes_for_project(project) }
          .compact
      end

      def build_attributes_for_project(project)
        {
          project_id: project.id,
          shard_id: find_shard_id(project.repository_storage),
          disk_path: project.disk_path
        }
      end

      def find_shard_id(repository_storage)
        shard_finder.find_shard_id(repository_storage)
      end

      def shard_finder
        @shard_finder ||= ShardFinder.new
      end
    end
  end
end
