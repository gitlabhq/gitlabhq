# frozen_string_literal: true

module Gitlab
  module GitalyClient
    class NamespaceService
      extend Gitlab::TemporarilyAllow

      NamespaceServiceAccessError = Class.new(StandardError)
      ALLOW_KEY = :allow_namespace

      def self.allow
        temporarily_allow(ALLOW_KEY) { yield }
      end

      def self.denied?
        !temporarily_allowed?(ALLOW_KEY)
      end

      def initialize(storage)
        raise NamespaceServiceAccessError if self.class.denied?

        @storage = storage
      end

      def add(name)
        request = Gitaly::AddNamespaceRequest.new(storage_name: @storage, name: name)

        gitaly_client_call(:add_namespace, request, timeout: GitalyClient.fast_timeout)
      end

      def remove(name)
        request = Gitaly::RemoveNamespaceRequest.new(storage_name: @storage, name: name)

        gitaly_client_call(:remove_namespace, request, timeout: GitalyClient.long_timeout)
      end

      def rename(from, to)
        request = Gitaly::RenameNamespaceRequest.new(storage_name: @storage, from: from, to: to)

        gitaly_client_call(:rename_namespace, request, timeout: GitalyClient.fast_timeout)
      end

      private

      def gitaly_client_call(type, request, timeout: nil)
        GitalyClient.call(@storage, :namespace_service, type, request, timeout: timeout)
      end
    end
  end
end
