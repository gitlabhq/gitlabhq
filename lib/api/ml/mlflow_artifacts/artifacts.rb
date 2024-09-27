# frozen_string_literal: true

require 'mime/types'

module API
  # MLFlow integration API, replicating the Rest API https://www.mlflow.org/docs/latest/rest-api.html#rest-api
  module Ml
    module MlflowArtifacts
      class Artifacts < ::API::Base
        feature_category :mlops
        helpers ::API::Helpers::PackagesHelpers

        before do
          check_api_read!
          check_api_model_registry_read!
        end

        desc 'MLflow artifact API' do
          detail 'MLflow artifacts mapping to GitLab artifacts'
        end

        route_setting :api, write: true
        route_setting :model_registry, write: true
        params do
          optional :path, type: String, desc: 'Path to the artifact, MLflow usually send the version'
        end
        get 'artifacts', urgency: :low do
          package_files = { files: list_model_artifacts(user_project, params[:path]).all }
          present package_files, with: Entities::Ml::MlflowArtifacts::ArtifactsList
        end

        get 'artifacts/:model_version/*file_path', format: false, urgency: :low do
          present_package_file!(find_model_artifact(user_project, params[:model_version],
            CGI.escape(params[:file_path])))
        end
      end
    end
  end
end
