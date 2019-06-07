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
        "http://#{service.dig('status', 'domain')}"
      end

      expose :description do |service|
        service.dig(
          'spec',
          'runLatest',
          'configuration',
          'revisionTemplate',
          'metadata',
          'annotations',
          'Description')
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
    end
  end
end
