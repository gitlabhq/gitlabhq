# frozen_string_literal: true

module Gitlab
  module GitalyClient
    class ObjectPoolService
      attr_reader :object_pool, :storage

      def initialize(object_pool)
        @object_pool = object_pool.gitaly_object_pool
        @storage = object_pool.storage
      end

      def create(repository)
        request = Gitaly::CreateObjectPoolRequest.new(
          object_pool: object_pool,
          origin: repository.gitaly_repository)

        GitalyClient.call(storage, :object_pool_service, :create_object_pool,
                          request, timeout: GitalyClient.medium_timeout)
      end

      def delete
        request = Gitaly::DeleteObjectPoolRequest.new(object_pool: object_pool)

        GitalyClient.call(storage, :object_pool_service, :delete_object_pool,
                          request, timeout: GitalyClient.long_timeout)
      end

      def link_repository(repository)
        request = Gitaly::LinkRepositoryToObjectPoolRequest.new(
          object_pool: object_pool,
          repository: repository.gitaly_repository
        )

        GitalyClient.call(storage, :object_pool_service, :link_repository_to_object_pool,
                          request, timeout: GitalyClient.fast_timeout)
      end

      def fetch(repository)
        request = Gitaly::FetchIntoObjectPoolRequest.new(
          object_pool: object_pool,
          origin: repository.gitaly_repository
        )

        GitalyClient.call(storage, :object_pool_service, :fetch_into_object_pool,
                          request, timeout: GitalyClient.long_timeout)
      end
    end
  end
end
