# frozen_string_literal: true

module Admin
  class DatabaseDiagnosticsController < Admin::ApplicationController
    feature_category :database
    authorize! :read_admin_database_diagnostics, only: %i[index run_collation_check collation_check_results]

    def index
      # Just render the view
    end

    def run_collation_check
      job_id = ::Database::CollationCheckerWorker.perform_async # rubocop:disable CodeReuse/Worker -- Simple direct call

      render json: { status: 'scheduled', job_id: job_id }
    end

    def collation_check_results
      results_json = Rails.cache.read(::Database::CollationCheckerWorker::COLLATION_CHECK_CACHE_KEY)

      if results_json.present?
        results = Gitlab::Json.parse(results_json)
        render json: results
      else
        render json: { error: 'No results available yet' }, status: :not_found
      end
    end
  end
end
