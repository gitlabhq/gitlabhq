# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    # This module is used to write the full path of all projects to
    # the git repository config file.
    # Storing the full project path in the git config allows admins to
    # easily identify a project when it is using hashed storage.
    module BackfillProjectFullpathInRepoConfig
      module Storage
        # Class that returns the disk path for a project using hashed storage
        class HashedProject
          attr_accessor :project

          ROOT_PATH_PREFIX = '@hashed'.freeze

          def initialize(project)
            @project = project
          end

          def disk_path
            "#{ROOT_PATH_PREFIX}/#{disk_hash[0..1]}/#{disk_hash[2..3]}/#{disk_hash}"
          end

          def disk_hash
            @disk_hash ||= Digest::SHA2.hexdigest(project.id.to_s) if project.id
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

      # Concern used by Project and Namespace to determine the full
      # route the the project
      module Routable
        extend ActiveSupport::Concern

        def full_path
          @full_path ||= build_full_path
        end

        def build_full_path
          if parent && path
            parent.full_path + '/' + path
          else
            path
          end
        end
      end

      # Class used to interact with repository using Gitaly
      class Repository
        attr_reader :storage

        def initialize(storage, relative_path)
          @storage = storage
          @relative_path = relative_path
        end

        def gitaly_repository
          Gitaly::Repository.new(storage_name: @storage, relative_path: @relative_path)
        end
      end

      # Namespace can be a user or group. It can be the root or a
      # child of another namespace.
      class Namespace < ActiveRecord::Base
        self.table_name = 'namespaces'

        include Routable

        belongs_to :parent, class_name: "Namespace"
      end

      # Project is where the repository (etc.) is stored
      class Project < ActiveRecord::Base
        self.table_name = 'projects'

        include Routable
        include EachBatch

        FULLPATH_CONFIG_KEY = 'gitlab.fullpath'

        belongs_to :namespace
        delegate :disk_path, to: :storage
        alias_method :parent, :namespace

        def add_fullpath_config
          entries = { FULLPATH_CONFIG_KEY => full_path }

          repository_service.set_config(entries)
        end

        def remove_fullpath_config
          repository_service.delete_config([FULLPATH_CONFIG_KEY])
        end

        def storage
          @storage ||=
            if hashed_storage?
              Storage::HashedProject.new(self)
            else
              Storage::LegacyProject.new(self)
            end
        end

        def hashed_storage?
          self.storage_version && self.storage_version >= 1
        end

        def repository
          @repository ||= Repository.new(repository_storage, disk_path + '.git')
        end

        def repository_service
          @repository_service ||= Gitlab::GitalyClient::RepositoryService.new(repository)
        end
      end

      # Class to add the fullpath to the git repo config
      class Up
        def perform(start_id, end_id)
          Project.where(id: start_id..end_id).each do |project|
            project.add_fullpath_config
          end
        end
      end

      # Class to rollback adding the fullpath to the git repo config
      class Down
        def perform(start_id, end_id)
          Project.where(id: start_id..end_id).each do |project|
            project.remove_fullpath_config
          end
        end
      end
    end
  end
end
