# frozen_string_literal: true

module API
  # MLFlow integration API, replicating the Rest API https://www.mlflow.org/docs/latest/rest-api.html#rest-api
  module Ml
    module Mlflow
      class Entrypoint < ::API::Base
        include APIGuard

        # The first part of the url is the namespace, the second part of the URL is what the MLFlow client calls
        MLFLOW_API_PREFIX = ':id/ml/mlflow/api/2.0/mlflow/'

        helpers ::API::Helpers::RelatedResourcesHelpers
        helpers ::API::Ml::Mlflow::ApiHelpers

        allow_access_with_scope :api
        allow_access_with_scope :read_api, if: ->(request) { request.get? || request.head? }

        feature_category :mlops

        content_type :json, 'application/json'
        default_format :json

        before do
          # MLFlow Client considers any status code different than 200 an error, even 201
          status 200

          authenticate!
        end

        rescue_from ActiveRecord::ActiveRecordError do |e|
          invalid_parameter!(e.message)
        end

        params do
          requires :id, types: [String, Integer], desc: 'The ID or URL-encoded path of the project'
        end
        resource :projects, requirements: API::NAMESPACE_OR_PROJECT_REQUIREMENTS do
          desc 'API to interface with MLflow Client, REST API version 1.28.0' do
            detail 'MLflow compatible API.'
          end
          namespace MLFLOW_API_PREFIX do
            mount ::API::Ml::Mlflow::Experiments
            mount ::API::Ml::Mlflow::ModelVersions
            mount ::API::Ml::Mlflow::Runs
            mount ::API::Ml::Mlflow::RegisteredModels
          end
        end
      end
    end
  end
end
