# frozen_string_literal: true

class AddTimestampToSchemaMigration < ActiveRecord::Migration[6.1]
  def up
    # Add a nullable column with default null first
    add_column :schema_migrations, :finished_at, :timestamptz

    # Change default to NOW() for new records
    change_column_default :schema_migrations, :finished_at, -> { 'NOW()' }
  end

  def down
    remove_column :schema_migrations, :finished_at
  end
end
