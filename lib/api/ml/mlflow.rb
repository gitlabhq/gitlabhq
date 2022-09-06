# frozen_string_literal: true

require 'mime/types'

module API
  # MLFlow integration API, replicating the Rest API https://www.mlflow.org/docs/latest/rest-api.html#rest-api
  module Ml
    class Mlflow < ::API::Base
      # The first part of the url is the namespace, the second part of the URL is what the MLFlow client calls
      MLFLOW_API_PREFIX = ':id/ml/mflow/api/2.0/mlflow/'

      before do
        authenticate!
        not_found! unless Feature.enabled?(:ml_experiment_tracking, user_project)
      end

      feature_category :mlops

      content_type :json, 'application/json'
      default_format :json

      helpers do
        def resource_not_found!
          render_structured_api_error!({ error_code: 'RESOURCE_DOES_NOT_EXIST' }, 404)
        end

        def resource_already_exists!
          render_structured_api_error!({ error_code: 'RESOURCE_ALREADY_EXISTS' }, 400)
        end
      end

      params do
        requires :id, type: String, desc: 'The ID of a project'
      end
      resource :projects, requirements: API::NAMESPACE_OR_PROJECT_REQUIREMENTS do
        desc 'API to interface with MLFlow Client, REST API version 1.28.0' do
          detail 'This feature is gated by :ml_experiment_tracking.'
        end
        namespace MLFLOW_API_PREFIX do
          resource :experiments do
            desc 'Fetch experiment by experiment_id' do
              success Entities::Ml::Mlflow::GetExperiment
              detail 'https://www.mlflow.org/docs/1.28.0/rest-api.html#get-experiment'
            end
            params do
              optional :experiment_id, type: String, default: '', desc: 'Experiment ID, in reference to the project'
            end
            get 'get', urgency: :low do
              experiment = ::Ml::Experiment.by_project_id_and_iid(user_project.id, params[:experiment_id])

              resource_not_found! unless experiment

              present experiment, with: Entities::Ml::Mlflow::GetExperiment
            end

            desc 'Fetch experiment by experiment_name' do
              success Entities::Ml::Mlflow::GetExperiment
              detail 'https://www.mlflow.org/docs/1.28.0/rest-api.html#get-experiment-by-name'
            end
            params do
              optional :experiment_name, type: String, default: '', desc: 'Experiment name'
            end
            get 'get-by-name', urgency: :low do
              experiment = ::Ml::Experiment.by_project_id_and_name(user_project, params[:experiment_name])

              resource_not_found! unless experiment

              present experiment, with: Entities::Ml::Mlflow::GetExperiment
            end

            desc 'Create experiment' do
              success Entities::Ml::Mlflow::NewExperiment
              detail 'https://www.mlflow.org/docs/1.28.0/rest-api.html#create-experiment'
            end
            params do
              requires :name, type: String, desc: 'Experiment name'
              optional :artifact_location, type: String, desc: 'This will be ignored'
              optional :tags, type: Array, desc: 'This will be ignored'
            end
            post 'create', urgency: :low do
              resource_already_exists! if ::Ml::Experiment.has_record?(user_project.id, params[:name])

              experiment = ::Ml::Experiment.create!(name: params[:name],
                                                    user: current_user,
                                                    project: user_project)

              present experiment, with: Entities::Ml::Mlflow::NewExperiment
            end
          end
        end
      end
    end
  end
end
