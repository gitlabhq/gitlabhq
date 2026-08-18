# frozen_string_literal: true

module Admin
  class DatabaseDiagnosticsController < Admin::ApplicationController
    include Gitlab::InternalEventsTracking

    feature_category :database
    authorize! :read_admin_database_diagnostics,
      only: %i[index run_collation_check collation_check_results run_schema_check schema_check_results
        run_lfk_backlog_check lfk_backlog_check_results]

    WORKER_CONFIGS = {
      collation: {
        worker: ::Database::CollationCheckerWorker,
        cache_key: ::Database::CollationCheckerWorker::COLLATION_CHECK_CACHE_KEY
      },
      schema: {
        worker: ::Database::SchemaCheckerWorker,
        cache_key: ::Database::SchemaCheckerWorker::SCHEMA_CHECK_CACHE_KEY
      },
      lfk_backlog: {
        worker: ::Database::LooseForeignKeysBacklogCheckerWorker,
        cache_key: ::Database::LooseForeignKeysBacklogCheckerWorker::BACKLOG_CHECK_CACHE_KEY
      }
    }.freeze

    def index
      @database_information = ::Gitlab::Database::DatabaseInformation.execute

      track_internal_event('visit_db_diagnostics_page', user: current_user)
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

    def run_lfk_backlog_check
      # Gate scheduling of this net-new worker so it is not enqueued from the web fleet before the
      # Sidekiq fleet has been updated to know the class during a rolling deploy. Enable after rollout.
      unless lfk_backlog_diagnostic_enabled?
        return render json: { error: 'Loose foreign keys backlog diagnostic is not enabled' },
          status: :service_unavailable
      end

      run_check(:lfk_backlog)
    end

    def lfk_backlog_check_results
      check_results(:lfk_backlog)
    end

    private

    def lfk_backlog_diagnostic_enabled?
      Feature.enabled?(:loose_foreign_keys_backlog_diagnostic, :instance, type: :ops)
    end

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
        results = Gitlab::Json.safe_parse(results_json)
        render json: results
      else
        render json: { error: 'No results available yet' }, status: :not_found
      end
    end
  end
end
