# frozen_string_literal: true

module Admin
  class BackgroundMigrationsController < ApplicationController
    feature_category :database
    urgency :low

    around_action :support_multiple_databases

    def index
      @relations_by_tab = {
        'queued' => batched_migration_class.queued.queue_order,
        'finalizing' => batched_migration_class.finalizing.queue_order,
        'failed' => batched_migration_class.with_status(:failed).queue_order,
        'finished' => batched_migration_class.with_status(:finished).queue_order.reverse_order
      }

      @current_tab = @relations_by_tab.key?(safe_params[:tab]) ? safe_params[:tab] : 'queued'
      @migrations = @relations_by_tab[@current_tab].page(pagination_params[:page])
      @successful_rows_counts = batched_migration_class.successful_rows_counts(@migrations.map(&:id))
      @databases = Gitlab::Database.db_config_names(with_schema: :gitlab_shared)
    end

    def show
      @migration = batched_migration_class.find(safe_params[:id])

      @failed_jobs = @migration.batched_jobs.with_status(:failed).page(pagination_params[:page])
    end

    def pause
      migration = batched_migration_class.find(safe_params[:id])
      migration.pause!

      redirect_back fallback_location: { action: 'index' }
    end

    def resume
      migration = batched_migration_class.find(safe_params[:id])
      migration.execute!

      redirect_back fallback_location: { action: 'index' }
    end

    def retry
      migration = batched_migration_class.find(safe_params[:id])
      migration.retry_failed_jobs! if migration.failed?

      redirect_back fallback_location: { action: 'index' }
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

    def batched_migration_class
      @batched_migration_class ||= Gitlab::Database::BackgroundMigration::BatchedMigration
    end

    def safe_params
      params.permit(:id, :database, :tab)
    end
  end
end
