# frozen_string_literal: true

require 'mime/types'

module API
  # MLFlow integration API, replicating the Rest API https://www.mlflow.org/docs/latest/rest-api.html#rest-api
  module Ml
    module Mlflow
      class Runs < ::API::Base
        feature_category :mlops

        before do
          check_api_read!
          check_api_write! unless request.get? || request.head?
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
              with: Entities::Ml::Mlflow::GetRun
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
            present candidate, with: Entities::Ml::Mlflow::GetRun
          end

          desc 'Searches runs/candidates within a project' do
            success Entities::Ml::Mlflow::Run
            detail 'https://www.mlflow.org/docs/1.28.0/rest-api.html#search-runs' \
                   'experiment_ids supports only a single experiment ID.' \
                   'Introduced in GitLab 16.4'
          end
          params do
            requires :experiment_ids,
              type: Array,
              desc: 'IDs of the experiments to get searches from, relative to the project'
            optional :max_results,
              type: Integer,
              desc: 'Maximum number of runs/candidates to fetch in a page. Default is 200, maximum in 1000',
              default: 200
            optional :order_by,
              type: String,
              desc: 'Order criteria. Can be by a column of the run/candidate (created_at, name) or by a metric if' \
                    'prefixed by `metrics`. Valid examples: `created_at`, `created_at DESC`, `metrics.my_metric DESC`' \
                    'Sorting by candidate parameter or metadata is not supported.',
              default: 'created_at DESC'
            optional :page_token,
              type: String,
              desc: 'Token for pagination'
          end
          post 'search', urgency: :low do
            params[:experiment_id] = params[:experiment_ids][0]

            max_results = [params[:max_results], 1000].min
            finder_params = candidates_order_params(params)
            finder = ::Projects::Ml::CandidateFinder.new(experiment, finder_params)
            paginator = finder.execute.keyset_paginate(cursor: params[:page_token], per_page: max_results)

            result = {
              candidates: paginator.records,
              next_page_token: paginator.cursor_for_next_page
            }

            present result, with: Entities::Ml::Mlflow::SearchRuns
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

            present candidate, with: Entities::Ml::Mlflow::UpdateRun
          end

          desc 'Logs a metric to a run.' do
            summary 'Log a metric for a run. A metric is a key-value pair (string key, float value) with an ' \
                    'associated timestamp. Examples include the various metrics that represent ML model accuracy. ' \
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
            summary 'Log a param used for a run. A param is a key-value pair (string key, string value). ' \
                    'Examples include hyperparameters used for ML model training and constant dates and values ' \
                    'used in an ETL pipeline. A param can be logged only once for a run, duplicate will be .' \
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
            summary 'Log a batch of metrics and params for a run. Validation errors will block the entire batch, ' \
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

          desc 'Delete a run.' do
            summary 'Delete a run.'

            detail 'https://mlflow.org/docs/2.16.0/rest-api.html#delete-run'
          end
          params do
            requires :run_id, type: String, desc: 'UUID of the run.'
          end
          post 'delete', urgency: :low do
            destroy = ::Ml::DestroyCandidateService.new(candidate, current_user).execute
            if destroy.success?
              present({})
            else
              render_api_error!(destroy.message.first, 400)
            end
          end
        end
      end
    end
  end
end
