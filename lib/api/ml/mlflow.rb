# frozen_string_literal: true

require 'mime/types'

module API
  # MLFlow integration API, replicating the Rest API https://www.mlflow.org/docs/latest/rest-api.html#rest-api
  module Ml
    class Mlflow < ::API::Base
      include APIGuard

      # The first part of the url is the namespace, the second part of the URL is what the MLFlow client calls
      MLFLOW_API_PREFIX = ':id/ml/mlflow/api/2.0/mlflow/'

      allow_access_with_scope :api
      allow_access_with_scope :read_api, if: -> (request) { request.get? || request.head? }

      feature_category :mlops

      content_type :json, 'application/json'
      default_format :json

      before do
        # MLFlow Client considers any status code different than 200 an error, even 201
        status 200

        authenticate!

        not_found! unless Feature.enabled?(:ml_experiment_tracking, user_project)
      end

      rescue_from ActiveRecord::ActiveRecordError do |e|
        invalid_parameter!(e.message)
      end

      helpers do
        def resource_not_found!
          render_structured_api_error!({ error_code: 'RESOURCE_DOES_NOT_EXIST' }, 404)
        end

        def resource_already_exists!
          render_structured_api_error!({ error_code: 'RESOURCE_ALREADY_EXISTS' }, 400)
        end

        def invalid_parameter!(message = nil)
          render_structured_api_error!({ error_code: 'INVALID_PARAMETER_VALUE', message: message }, 400)
        end

        def experiment_repository
          ::Ml::ExperimentTracking::ExperimentRepository.new(user_project, current_user)
        end

        def candidate_repository
          ::Ml::ExperimentTracking::CandidateRepository.new(user_project, current_user)
        end

        def experiment
          @experiment ||= find_experiment!(params[:experiment_id], params[:experiment_name])
        end

        def candidate
          @candidate ||= find_candidate!(params[:run_id])
        end

        def find_experiment!(iid, name)
          experiment_repository.by_iid_or_name(iid: iid, name: name) || resource_not_found!
        end

        def find_candidate!(iid)
          candidate_repository.by_iid(iid) || resource_not_found!
        end

        def packages_url
          path = api_v4_projects_packages_generic_package_version_path(
            id: user_project.id, package_name: '', file_name: ''
          )
          path = path.delete_suffix('/package_version')

          "#{request.base_url}#{path}"
        end
      end

      params do
        requires :id, types: [String, Integer], desc: 'The ID or URL-encoded path of the project'
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

          resource :runs do
            desc 'Creates a Run.' do
              success Entities::Ml::Mlflow::Run
              detail 'MLFlow Runs map to GitLab Candidates. https://www.mlflow.org/docs/1.28.0/rest-api.html#create-run'
            end
            params do
              requires :experiment_id, type: Integer,
                                       desc: 'Id for the experiment, relative to the project'
              optional :start_time, type: Integer,
                                    desc: 'Unix timestamp in milliseconds of when the run started.',
                                    default: 0
              optional :user_id, type: String, desc: 'This will be ignored'
              optional :tags, type: Array, desc: 'Tags are stored, but not displayed'
              optional :run_name, type: String, desc: 'A name for this run'
            end
            post 'create', urgency: :low do
              present candidate_repository.create!(experiment, params[:start_time], params[:tags], params[:run_name]),
                      with: Entities::Ml::Mlflow::Run, packages_url: packages_url
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
              present candidate, with: Entities::Ml::Mlflow::Run, packages_url: packages_url
            end

            desc 'Updates a Run.' do
              success Entities::Ml::Mlflow::UpdateRun
              detail 'MLFlow Runs map to GitLab Candidates. https://www.mlflow.org/docs/1.28.0/rest-api.html#update-run'
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
              candidate_repository.update(candidate, params[:status], params[:end_time])

              present candidate, with: Entities::Ml::Mlflow::UpdateRun, packages_url: packages_url
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
              candidate_repository.add_metric!(
                candidate,
                params[:key],
                params[:value],
                params[:timestamp],
                params[:step]
              )

              {}
            end

            desc 'Logs a parameter to a run.' do
              summary 'Log a param used for a run. A param is a key-value pair (string key, string value). '\
                      'Examples include hyperparameters used for ML model training and constant dates and values '\
                      'used in an ETL pipeline. A param can be logged only once for a run, duplicate will be .'\
                      'ignored'

              detail  'https://www.mlflow.org/docs/1.28.0/rest-api.html#log-param'
            end
            params do
              requires :run_id, type: String, desc: 'UUID of the run.'
              requires :key, type: String, desc: 'Name for the parameter.'
              requires :value, type: String, desc: 'Value for the parameter.'
            end
            post 'log-parameter', urgency: :low do
              bad_request! unless candidate_repository.add_param!(candidate, params[:key], params[:value])

              {}
            end

            desc 'Sets a tag for a run.' do
              summary 'Sets a tag for a run. '

              detail  'https://www.mlflow.org/docs/1.28.0/rest-api.html#set-tag'
            end
            params do
              requires :run_id, type: String, desc: 'UUID of the run.'
              requires :key, type: String, desc: 'Name for the tag.'
              requires :value, type: String, desc: 'Value for the tag.'
            end
            post 'set-tag', urgency: :low do
              bad_request! unless candidate_repository.add_tag!(candidate, params[:key], params[:value])

              {}
            end

            desc 'Logs multiple parameters and metrics.' do
              summary 'Log a batch of metrics and params for a run. Validation errors will block the entire batch, '\
                      'duplicate errors will be ignored.'

              detail  'https://www.mlflow.org/docs/1.28.0/rest-api.html#log-param'
            end
            params do
              requires :run_id, type: String, desc: 'UUID of the run.'
              optional :metrics, type: Array, default: [] do
                requires :key, type: String, desc: 'Name for the metric.'
                requires :value, type: Float, desc: 'Value of the metric.'
                requires :timestamp, type: Integer, desc: 'Unix timestamp in milliseconds when metric was recorded'
                optional :step, type: Integer, desc: 'Step at which the metric was recorded'
              end
              optional :params, type: Array, default: [] do
                requires :key, type: String, desc: 'Name for the metric.'
                requires :value, type: String, desc: 'Value of the metric.'
              end
            end
            post 'log-batch', urgency: :low do
              candidate_repository.add_metrics(candidate, params[:metrics])
              candidate_repository.add_params(candidate, params[:params])
              candidate_repository.add_tags(candidate, params[:tags])

              {}
            end
          end
        end
      end
    end
  end
end
