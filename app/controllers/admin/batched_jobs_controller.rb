# frozen_string_literal: true

module Admin
  class BatchedJobsController < ApplicationController
    feature_category :database
    urgency :low

    around_action :support_multiple_databases

    def show
      @job = Gitlab::Database::BackgroundMigration::BatchedJob.find(safe_params[:id])

      @transition_logs = @job.batched_job_transition_logs
    end

    private

    def support_multiple_databases
      Gitlab::Database::SharedModel.using_connection(base_model.connection) do
        yield
      end
    end

    def base_model
      @selected_database = safe_params[:database] || Gitlab::Database::MAIN_DATABASE_NAME

      Gitlab::Database.database_base_models[@selected_database]
    end

    def safe_params
      params.permit(:id, :database)
    end
  end
end
