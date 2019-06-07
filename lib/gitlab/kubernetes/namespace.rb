# frozen_string_literal: true

module Gitlab
  module Kubernetes
    class Namespace
      attr_accessor :name

      def initialize(name, client)
        @name = name
        @client = client
      end

      def exists?
        @client.get_namespace(name)
      rescue ::Kubeclient::ResourceNotFoundError
        false
      end

      def create!
        resource = ::Kubeclient::Resource.new(metadata: { name: name })

        log_event(:begin_create)
        @client.create_namespace(resource)
      end

      def ensure_exists!
        exists? || create!
      rescue ::Kubeclient::HttpError => error
        log_create_failed(error)
        raise
      end

      private

      def log_create_failed(error)
        logger.error({
          exception: error.class.name,
          status_code: error.error_code,
          namespace: name,
          class_name: self.class.name,
          event: :failed_to_create_namespace,
          message: error.message
        })
      end

      def log_event(event)
        logger.info(
          namespace: name,
          class_name: self.class.name,
          event: event
        )
      end

      def logger
        @logger ||= Gitlab::Kubernetes::Logger.build
      end
    end
  end
end
