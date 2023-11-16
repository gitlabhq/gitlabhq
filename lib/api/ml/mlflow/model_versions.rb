# frozen_string_literal: true

module API
  module Ml
    module Mlflow
      class ModelVersions < ::API::Base
        feature_category :mlops

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
            check_api_model_registry_read!
            resource_not_found! unless params[:name] && params[:version]
            model_version = ::Ml::ModelVersions::GetModelVersionService.new(
              user_project, params[:name], params[:version]
            ).execute
            resource_not_found! unless model_version
            response = { model_version: model_version }
            present response, with: Entities::Ml::Mlflow::ModelVersions::Responses::Get
          end
        end
      end
    end
  end
end
