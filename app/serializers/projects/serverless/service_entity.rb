# frozen_string_literal: true

module Projects
  module Serverless
    class ServiceEntity < Grape::Entity
      include RequestAwareEntity

      expose :name do |service|
        service.dig('metadata', 'name')
      end

      expose :namespace do |service|
        service.dig('metadata', 'namespace')
      end

      expose :environment_scope do |service|
        service.dig('environment_scope')
      end

      expose :cluster_id do |service|
        service.dig('cluster_id')
      end

      expose :detail_url do |service|
        project_serverless_path(
          request.project,
          service.dig('environment_scope'),
          service.dig('metadata', 'name'))
      end

      expose :podcount do |service|
        service.dig('podcount')
      end

      expose :metrics_url do |service|
        project_serverless_metrics_path(
          request.project,
          service.dig('environment_scope'),
          service.dig('metadata', 'name')) + ".json"
      end

      expose :created_at do |service|
        service.dig('metadata', 'creationTimestamp')
      end

      expose :url do |service|
        knative_06_07_url(service) || knative_05_url(service)
      end

      expose :description do |service|
        knative_07_description(service) || knative_05_06_description(service)
      end

      expose :image do |service|
        service.dig(
          'spec',
          'runLatest',
          'configuration',
          'build',
          'template',
          'name')
      end

      private

      def knative_07_description(service)
        service.dig(
          'spec',
          'template',
          'metadata',
          'annotations',
          'Description'
        )
      end

      def knative_05_url(service)
        "http://#{service.dig('status', 'domain')}"
      end

      def knative_06_07_url(service)
        service.dig('status', 'url')
      end

      def knative_05_06_description(service)
        service.dig(
          'spec',
          'runLatest',
          'configuration',
          'revisionTemplate',
          'metadata',
          'annotations',
          'Description')
      end
    end
  end
end
