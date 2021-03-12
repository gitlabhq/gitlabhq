# frozen_string_literal: true

class ChangeBatchedBackgroundMigrationsBatchClassNameDefault < ActiveRecord::Migration[6.0]
  DOWNTIME = false

  def change
    change_column_default :batched_background_migrations, :batch_class_name,
      from: 'Gitlab::Database::BackgroundMigration::PrimaryKeyBatchingStrategy', to: 'PrimaryKeyBatchingStrategy'
  end
end
