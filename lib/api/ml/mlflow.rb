# frozen_string_literal: true

require 'mime/types'

module API
  # MLFlow integration API, replicating the Rest API https://www.mlflow.org/docs/latest/rest-api.html#rest-api
  module Ml
    class Mlflow < ::API::Base
      include APIGuard

      # The first part of the url is the namespace, the second part of the URL is what the MLFlow client calls
      MLFLOW_API_PREFIX = ':id/ml/mflow/api/2.0/mlflow/'

      allow_access_with_scope :api
      allow_access_with_scope :read_api, if: -> (request) { request.get? || request.head? }

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
              success Entities::Ml::Mlflow::Experiment
              detail 'https://www.mlflow.org/docs/1.28.0/rest-api.html#get-experiment'
            end
            params do
              optional :experiment_id, type: String, default: '', desc: 'Experiment ID, in reference to the project'
            end
            get 'get', urgency: :low do
              experiment = ::Ml::Experiment.by_project_id_and_iid(user_project.id, params[:experiment_id])

              resource_not_found! unless experiment

              present experiment, with: Entities::Ml::Mlflow::Experiment
            end

            desc 'Fetch experiment by experiment_name' do
              success Entities::Ml::Mlflow::Experiment
              detail 'https://www.mlflow.org/docs/1.28.0/rest-api.html#get-experiment-by-name'
            end
            params do
              optional :experiment_name, type: String, default: '', desc: 'Experiment name'
            end
            get 'get-by-name', urgency: :low do
              experiment = ::Ml::Experiment.by_project_id_and_name(user_project, params[:experiment_name])

              resource_not_found! unless experiment

              present experiment, with: Entities::Ml::Mlflow::Experiment
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

          resource :runs do
            desc 'Creates a Run.' do
              success Entities::Ml::Mlflow::Run
              detail  ['https://www.mlflow.org/docs/1.28.0/rest-api.html#create-run',
                       'MLFlow Runs map to GitLab Candidates']
            end
            params do
              requires :experiment_id, type: Integer,
                                       desc: 'Id for the experiment, relative to the project'
              optional :start_time, type: Integer,
                                    desc: 'Unix timestamp in milliseconds of when the run started.',
                                    default: 0
              optional :user_id, type: String, desc: 'This will be ignored'
              optional :tags, type: Array, desc: 'This will be ignored'
            end
            post 'create', urgency: :low do
              experiment = ::Ml::Experiment.by_project_id_and_iid(user_project.id, params[:experiment_id].to_i)

              resource_not_found! unless experiment

              candidate = experiment.candidates.create!(
                user: current_user,
                start_time: params[:start_time] || 0
              )

              present candidate, with: Entities::Ml::Mlflow::Run
            end

            namespace do
              after_validation do
                @candidate = ::Ml::Candidate.with_project_id_and_iid(
                  user_project.id,
                  params[:run_id]
                )

                resource_not_found! unless @candidate
              end

              desc 'Gets an MLFlow Run, which maps to GitLab Candidates' do
                success Entities::Ml::Mlflow::Run
                detail 'https://www.mlflow.org/docs/1.28.0/rest-api.html#get-run'
              end
              params do
                requires :run_id, type: String, desc: 'UUID of the candidate.'
                optional :run_uuid, type: String, desc: 'This parameter is ignored'
              end
              get 'get', urgency: :low do
                present @candidate, with: Entities::Ml::Mlflow::Run
              end

              desc 'Updates a Run.' do
                success Entities::Ml::Mlflow::UpdateRun
                detail  ['https://www.mlflow.org/docs/1.28.0/rest-api.html#update-run',
                         'MLFlow Runs map to GitLab Candidates']
              end
              params do
                requires :run_id, type: String, desc: 'UUID of the candidate.'
                optional :status, type: String,
                                  values: ::Ml::Candidate.statuses.keys.map(&:upcase),
                                  desc: "Status of the run. Accepts: " \
                                        "#{::Ml::Candidate.statuses.keys.map(&:upcase)}."
                optional :end_time, type: Integer, desc: 'Ending time of the run'
              end
              post 'update', urgency: :low do
                @candidate.status = params[:status].downcase if params[:status]
                @candidate.end_time = params[:end_time] if params[:end_time]

                @candidate.save if @candidate.valid?

                present @candidate, with: Entities::Ml::Mlflow::UpdateRun
              end

              desc 'Logs a metric to a run.' do
                summary 'Log a metric for a run. A metric is a key-value pair (string key, float value) with an '\
                        'associated timestamp. Examples include the various metrics that represent ML model accuracy. '\
                        'A metric can be logged multiple times.'
                detail  'https://www.mlflow.org/docs/1.28.0/rest-api.html#log-metric'
              end
              params do
                requires :run_id, type: String, desc: 'UUID of the run.'
                requires :key, type: String, desc: 'Name for the metric.'
                requires :value, type: Float, desc: 'Value of the metric.'
                requires :timestamp, type: Integer, desc: 'Unix timestamp in milliseconds when metric was recorded'
                optional :step, type: Integer, desc: 'Step at which the metric was recorded'
              end
              post 'log-metric', urgency: :low do
                @candidate.metrics.create!(
                  name: params[:key],
                  value: params[:value],
                  tracked_at: params[:timestamp],
                  step: params[:step]
                )

                {}
              end
            end
          end
        end
      end
    end
  end
end
