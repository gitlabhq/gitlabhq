# frozen_string_literal: true

module Projects
  module Serverless
    class ServiceEntity < Grape::Entity
      include RequestAwareEntity

      expose :name
      expose :namespace
      expose :environment_scope
      expose :podcount
      expose :created_at
      expose :image
      expose :description
      expose :url

      expose :detail_url do |service|
        project_serverless_path(
          request.project,
          service.environment_scope,
          service.name)
      end

      expose :metrics_url do |service|
        project_serverless_metrics_path(
          request.project,
          service.environment_scope,
          service.name, format: :json)
      end

      expose :cluster_id do |service|
        service.cluster&.id
      end
    end
  end
end
