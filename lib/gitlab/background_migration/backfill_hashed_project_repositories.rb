# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    # Class the will create rows in project_repositories for all
    # projects that are on hashed storage
    class BackfillHashedProjectRepositories
      # Model for a Shard
      class Shard < ActiveRecord::Base
        self.table_name = 'shards'

        def self.by_name(name)
          to_a.detect { |shard| shard.name == name } || create_by(name: name)
        rescue ActiveRecord::RecordNotUnique
          retry
        end
      end

      # Class that will find or create the shard by name.
      # There is only a small set of shards, which would not change quickly,
      # so look them up from memory instead of hitting the DB each time.
      class ShardFinder
        def find(name)
          shards.detect { |shard| shard.name == name } || create!(name)
        rescue ActiveRecord::RecordNotUnique
          load!
          retry
        end

        private

        def create!(name)
          Shard.create!(name: name).tap { |shard| @shards << shard }
        end

        def shards
          @shards || load!
        end

        def load!
          @shards = Shard.all.to_a
        end
      end

      # Model for a ProjectRepository
      class ProjectRepository < ActiveRecord::Base
        self.table_name = 'project_repositories'

        belongs_to :project, inverse_of: :project_repository
      end

      # Model for a Project
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
            where(arel_table[:storage_version].gteq(HASHED_STORAGE_FEATURES[:repository]))
          end

          def without_project_repository
            cond = ProjectRepository.arel_table[:project_id].eq(nil)
            left_outer_joins(:project_repository).where(cond)
          end

          def left_outer_joins(relation)
            return super if Gitlab.rails5?

            # TODO Rails 4?
          end
        end

        def project_repository_attributes(shard_finder)
          return unless hashed_storage?

          {
            project_id: id,
            shard_id: shard_finder.find(repository_storage).id,
            disk_path: hashed_disk_path
          }
        end

        private

        def hashed_storage?
          self.storage_version && self.storage_version >= 1
        end

        def hashed_disk_path
          "#{HASHED_PATH_PREFIX}/#{disk_hash[0..1]}/#{disk_hash[2..3]}/#{disk_hash}"
        end

        def disk_hash
          @disk_hash ||= Digest::SHA2.hexdigest(id.to_s) if id
        end
      end

      def perform(start_id, stop_id)
        Gitlab::Database.bulk_insert(:project_repositories, project_repositories(start_id, stop_id))
      end

      private

      def project_repositories(start_id, stop_id)
        Project.on_hashed_storage.without_project_repository
          .where(id: start_id..stop_id)
          .map { |project| project.project_repository_attributes(shard_finder) }
          .compact
      end

      def shard_finder
        @shard_finder ||= ShardFinder.new
      end
    end
  end
end
