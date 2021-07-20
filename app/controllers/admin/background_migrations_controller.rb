# frozen_string_literal: true

class Admin::BackgroundMigrationsController < Admin::ApplicationController
  feature_category :database

  def index
    @relations_by_tab = {
      'queued' => batched_migration_class.queued.queue_order,
      'failed' => batched_migration_class.failed.queue_order,
      'finished' => batched_migration_class.finished.queue_order.reverse_order
    }

    @current_tab = @relations_by_tab.key?(params[:tab]) ? params[:tab] : 'queued'
    @migrations = @relations_by_tab[@current_tab].page(params[:page])
    @successful_rows_counts = batched_migration_class.successful_rows_counts(@migrations.map(&:id))
  end

  def pause
    migration = batched_migration_class.find(params[:id])
    migration.paused!

    redirect_back fallback_location: { action: 'index' }
  end

  def resume
    migration = batched_migration_class.find(params[:id])
    migration.active!

    redirect_back fallback_location: { action: 'index' }
  end

  private

  def batched_migration_class
    Gitlab::Database::BackgroundMigration::BatchedMigration
  end
end
