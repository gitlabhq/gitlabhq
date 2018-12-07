# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    # Class that will create fill the project_repositories table
    # for all projects that are on hashed storage and an entry is
    # is missing in this table.
    class BackfillHashedProjectRepositories
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

          Shard.transaction(requires_new: true) do
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
          @shards = Hash[*Shard.all.map { |shard| [shard.name, shard.id] }.flatten]
        end
      end

      # ProjectRegistry model
      class ProjectRepository < ActiveRecord::Base
        self.table_name = 'project_repositories'

        belongs_to :project, inverse_of: :project_repository
      end

      # Project model
      class Project < ActiveRecord::Base
        self.table_name = 'projects'

        HASHED_PATH_PREFIX = '@hashed'

        HASHED_STORAGE_FEATURES = {
          repository: 1,
          attachments: 2
        }.freeze

        has_one :project_repository, inverse_of: :project

        class << self
          def on_hashed_storage
            where(Project.arel_table[:storage_version]
              .gteq(HASHED_STORAGE_FEATURES[:repository]))
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

        def hashed_storage?
          self.storage_version && self.storage_version >= 1
        end

        def hashed_disk_path
          "#{HASHED_PATH_PREFIX}/#{disk_hash[0..1]}/#{disk_hash[2..3]}/#{disk_hash}"
        end

        def disk_hash
          @disk_hash ||= Digest::SHA2.hexdigest(id.to_s)
        end
      end

      def perform(start_id, stop_id)
        Gitlab::Database.bulk_insert(:project_repositories, project_repositories(start_id, stop_id))
      end

      private

      def project_repositories(start_id, stop_id)
        Project.on_hashed_storage
          .without_project_repository
          .where(id: start_id..stop_id)
          .map { |project| build_attributes_for_project(project) }
          .compact
      end

      def build_attributes_for_project(project)
        return unless project.hashed_storage?

        {
          project_id: project.id,
          shard_id:   find_shard_id(project.repository_storage),
          disk_path:  project.hashed_disk_path
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
