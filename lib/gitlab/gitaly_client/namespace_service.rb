module Gitlab
  module GitalyClient
    class NamespaceService
      def initialize(storage)
        @storage = storage
      end

      def exists?(name)
        request = Gitaly::NamespaceExistsRequest.new(storage_name: @storage, name: name)

        gitaly_client_call(:namespace_exists, request).exists
      end

      def add(name)
        request = Gitaly::AddNamespaceRequest.new(storage_name: @storage, name: name)

        gitaly_client_call(:add_namespace, request)
      end

      def remove(name)
        request = Gitaly::RemoveNamespaceRequest.new(storage_name: @storage, name: name)

        gitaly_client_call(:remove_namespace, request)
      end

      def rename(from, to)
        request = Gitaly::RenameNamespaceRequest.new(storage_name: @storage, from: from, to: to)

        gitaly_client_call(:rename_namespace, request)
      end

      private

      def gitaly_client_call(type, request)
        GitalyClient.call(@storage, :namespace_service, type, request)
      end
    end
  end
end
