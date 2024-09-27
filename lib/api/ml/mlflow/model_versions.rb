# frozen_string_literal: true

module API
  module Ml
    module Mlflow
      class ModelVersions < ::API::Base
        feature_category :mlops

        before do
          check_api_read!
          check_api_model_registry_read!
          check_api_write! if route.settings.dig(:api, :write)
          check_api_model_registry_write! if route.settings.dig(:model_registry, :write)
        end

        resource 'model-versions' do
          desc 'Creates a Model Version.' do
            success Entities::Ml::Mlflow::ModelVersion
            detail 'MLFlow Model Versions map to GitLab Model Versions. https://mlflow.org/docs/2.6.0/rest-api.html#create-modelversion'
          end
          route_setting :api, write: true
          route_setting :model_registry, write: true
          params do
            # The name param is actually required, however it is listed as optional here
            # we can send a custom error response required by MLFlow
            optional :name, type: String,
              desc: 'Register model under this name This field is required.'
            optional :description, type: String,
              desc: 'Optional description for model version.'
            optional :tags, type: Array, desc: 'Additional metadata for a model version.'
          end
          post 'create', urgency: :low do
            result = ::Ml::CreateModelVersionService.new(
              model,
              {
                model_name: params[:name],
                description: params[:description],
                metadata: params[:tags],
                version: custom_version,
                user: current_user
              }
            ).execute

            invalid_parameter!(result.message) if result.error?

            present result.payload[:model_version], with: Entities::Ml::Mlflow::ModelVersion, root: :model_version
          end

          desc 'Fetch the download URI for the model version.' do
            success Entities::Ml::Mlflow::GetDownload
            detail 'Returns version in MLflow format "mlflow-artifacts:<version>" https://mlflow.org/docs/2.6.0/rest-api.html#get-download-uri-for-modelversion-artifacts'
          end
          params do
            requires :name, type: String, desc: 'Model version name'
            requires :version, type: Integer, desc: 'Model version ID'
          end
          get 'get-download-uri' do
            present params[:version], with: Entities::Ml::Mlflow::GetDownload
          end

          desc 'Fetch model version by name and version' do
            success Entities::Ml::Mlflow::ModelVersion
            detail 'https://mlflow.org/docs/2.6.0/rest-api.html#get-modelversion'
          end
          params do
            requires :name, type: String, desc: 'Model version name'
            requires :version, type: String, desc: 'Model version number'
          end
          get 'get', urgency: :low do
            present find_model_version(user_project, params[:name], params[:version]),
              with: Entities::Ml::Mlflow::ModelVersion, root: :model_version
          end

          desc 'Updates a Model Version.' do
            success Entities::Ml::Mlflow::ModelVersion
            detail 'https://mlflow.org/docs/2.6.0/rest-api.html#update-modelversion'
          end
          route_setting :api, write: true
          route_setting :model_registry, write: true
          params do
            # These params are actually required, however it is listed as optional here
            # we can send a custom error response required by MLFlow
            optional :name, type: String, desc: 'Model version name'
            optional :version, type: String, desc: 'Model version number'
            optional :description, type: String, desc: 'Model version description'
          end
          patch 'update', urgency: :low do
            invalid_parameter! unless params[:name] && params[:version] && params[:description]
            result = ::Ml::ModelVersions::UpdateModelVersionService.new(
              user_project, params[:name], params[:version], params[:description]
            ).execute
            update_failed! unless result.success?

            present result.payload, with: Entities::Ml::Mlflow::ModelVersion, root: :model_version
          end
        end
      end
    end
  end
end
