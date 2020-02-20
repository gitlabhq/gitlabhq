# frozen_string_literal: true

class AddEsBulkConfig < ActiveRecord::Migration[6.0]
  # Set this constant to true if this migration requires downtime.
  DOWNTIME = false

  def change
    add_column :application_settings, :elasticsearch_max_bulk_size_mb, :smallint, null: false, default: 10
    add_column :application_settings, :elasticsearch_max_bulk_concurrency, :smallint, null: false, default: 10
  end
end
