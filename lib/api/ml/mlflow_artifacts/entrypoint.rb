# frozen_string_literal: true

module API
  # MLFlow integration API, replicating the Rest API https://www.mlflow.org/docs/latest/rest-api.html#rest-api
  module Ml
    module MlflowArtifacts
      class Entrypoint < ::API::Base
        include APIGuard

        # The first part of the url is the namespace, the second part of the URL is what the MLFlow client calls
        MLFLOW_API_PREFIX = ':id/ml/mlflow/api/2.0/mlflow-artifacts/'

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

        params do
          requires :id, types: [String, Integer], desc: 'The ID or URL-encoded path of the project'
        end
        resource :projects, requirements: API::NAMESPACE_OR_PROJECT_REQUIREMENTS do
          desc 'API to interface with MLFlow Client, REST API version 2.16.0' do
            detail 'MLflow compatible API'
          end
          namespace MLFLOW_API_PREFIX do
            mount ::API::Ml::MlflowArtifacts::Artifacts
          end
        end
      end
    end
  end
end
