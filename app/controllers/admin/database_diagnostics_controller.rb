# frozen_string_literal: true

module Admin
  class DatabaseDiagnosticsController < Admin::ApplicationController
    feature_category :database
    authorize! :read_admin_database_diagnostics,
      only: %i[index run_collation_check collation_check_results run_schema_check schema_check_results]

    WORKER_CONFIGS = {
      collation: {
        worker: ::Database::CollationCheckerWorker,
        cache_key: ::Database::CollationCheckerWorker::COLLATION_CHECK_CACHE_KEY
      },
      schema: {
        worker: ::Database::SchemaCheckerWorker,
        cache_key: ::Database::SchemaCheckerWorker::SCHEMA_CHECK_CACHE_KEY
      }
    }.freeze

    def index
      # Just render the view
    end

    def run_collation_check
      run_check(:collation)
    end

    def run_schema_check
      run_check(:schema)
    end

    def collation_check_results
      check_results(:collation)
    end

    def schema_check_results
      check_results(:schema)
    end

    private

    def run_check(check_type)
      worker_class = WORKER_CONFIGS[check_type][:worker]
      job_id = worker_class.perform_async

      if job_id
        render json: { status: 'scheduled', job_id: job_id }
      else
        render json: { error: 'Failed to schedule job' }, status: :internal_server_error
      end
    end

    def check_results(check_type)
      cache_key = WORKER_CONFIGS[check_type][:cache_key]
      results_json = Rails.cache.read(cache_key)

      if results_json.present?
        results = Gitlab::Json.parse(results_json)
        render json: results
      else
        render json: { error: 'No results available yet' }, status: :not_found
      end
    end
  end
end
