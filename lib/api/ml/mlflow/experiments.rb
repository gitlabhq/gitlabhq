# frozen_string_literal: true

require 'mime/types'

module API
  # MLFlow integration API, replicating the Rest API https://www.mlflow.org/docs/latest/rest-api.html#rest-api
  module Ml
    module Mlflow
      class Experiments < ::API::Base
        feature_category :mlops

        resource :experiments do
          desc 'Fetch experiment by experiment_id' do
            success Entities::Ml::Mlflow::GetExperiment
            detail 'https://www.mlflow.org/docs/1.28.0/rest-api.html#get-experiment'
          end
          params do
            optional :experiment_id, type: String, default: '', desc: 'Experiment ID, in reference to the project'
          end
          get 'get', urgency: :low do
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
            present experiment, with: Entities::Ml::Mlflow::GetExperiment
          end

          desc 'List experiments' do
            success Entities::Ml::Mlflow::ListExperiment
            detail 'https://www.mlflow.org/docs/latest/rest-api.html#list-experiments'
          end
          get 'list', urgency: :low do
            response = { experiments: experiment_repository.all }

            present response, with: Entities::Ml::Mlflow::ListExperiment
          end

          desc 'Create experiment' do
            success Entities::Ml::Mlflow::NewExperiment
            detail 'https://www.mlflow.org/docs/1.28.0/rest-api.html#create-experiment'
          end
          params do
            requires :name, type: String, desc: 'Experiment name'
            optional :tags, type: Array, desc: 'Tags with information about the experiment'
            optional :artifact_location, type: String, desc: 'This will be ignored'
          end
          post 'create', urgency: :low do
            present experiment_repository.create!(params[:name], params[:tags]),
              with: Entities::Ml::Mlflow::NewExperiment
          rescue ActiveRecord::RecordInvalid
            resource_already_exists!
          end

          desc 'Sets a tag for an experiment.' do
            summary 'Sets a tag for an experiment. '

            detail  'https://www.mlflow.org/docs/1.28.0/rest-api.html#set-experiment-tag'
          end
          params do
            requires :experiment_id, type: String, desc: 'ID of the experiment.'
            requires :key, type: String, desc: 'Name for the tag.'
            requires :value, type: String, desc: 'Value for the tag.'
          end
          post 'set-experiment-tag', urgency: :low do
            bad_request! unless experiment_repository.add_tag!(experiment, params[:key], params[:value])

            {}
          end
        end
      end
    end
  end
end
