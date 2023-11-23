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
          desc 'Fetch model version by name and version' do
            success Entities::Ml::Mlflow::ModelVersions::Responses::Get
            detail 'https://mlflow.org/docs/2.6.0/rest-api.html#get-modelversion'
          end
          params do
            requires :name, type: String, desc: 'Model version name'
            requires :version, type: String, desc: 'Model version number'
          end
          get 'get', urgency: :low do
            resource_not_found! unless params[:name] && params[:version]
            model_version = ::Ml::ModelVersions::GetModelVersionService.new(
              user_project, params[:name], params[:version]
            ).execute
            resource_not_found! unless model_version
            response = { model_version: model_version }
            present response, with: Entities::Ml::Mlflow::ModelVersions::Responses::Get
          end

          desc 'Updates a Model Version.' do
            success Entities::Ml::Mlflow::ModelVersions::Responses::Update
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
            response = { model_version: result.payload }
            present response, with: Entities::Ml::Mlflow::ModelVersions::Responses::Update
          end
        end
      end
    end
  end
end
