# frozen_string_literal: true

module Gitlab
  module Git
    class ObjectPool
      # GL_REPOSITORY has to be passed for Gitlab::Git::Repositories, but not
      # used for ObjectPools.
      GL_REPOSITORY = ""

      delegate :exists?, :size, to: :repository
      delegate :delete, to: :object_pool_service

      attr_reader :storage, :relative_path, :source_repository, :gl_project_path

      def self.init_from_gitaly(gitaly_object_pool, source_repository)
        repository = gitaly_object_pool.repository

        new(
          repository.storage_name,
          repository.relative_path,
          source_repository,
          repository.gl_project_path
        )
      end

      def initialize(storage, relative_path, source_repository, gl_project_path)
        @storage = storage
        @relative_path = relative_path
        @source_repository = source_repository
        @gl_project_path = gl_project_path
      end

      def create
        object_pool_service.create(source_repository)
      end

      def link(to_link_repo)
        object_pool_service.link_repository(to_link_repo)
      end

      def gitaly_object_pool
        Gitaly::ObjectPool.new(repository: to_gitaly_repository)
      end

      def to_gitaly_repository
        Gitlab::GitalyClient::Util.repository(storage, relative_path, GL_REPOSITORY, gl_project_path)
      end

      # Allows for reusing other RPCs by 'tricking' Gitaly to think its a repository
      def repository
        @repository ||= Gitlab::Git::Repository.new(storage, relative_path, GL_REPOSITORY, gl_project_path)
      end

      def fetch
        object_pool_service.fetch(source_repository)
      end

      private

      def object_pool_service
        @object_pool_service ||= Gitlab::GitalyClient::ObjectPoolService.new(self)
      end

      def relative_path_to(pool_member_path)
        pool_path = Pathname.new("#{relative_path}#{File::SEPARATOR}")

        Pathname.new(pool_member_path).relative_path_from(pool_path).to_s
      end
    end
  end
end
