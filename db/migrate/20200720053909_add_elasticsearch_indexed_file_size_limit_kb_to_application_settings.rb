# frozen_string_literal: true

class AddElasticsearchIndexedFileSizeLimitKbToApplicationSettings < ActiveRecord::Migration[6.0]
  DOWNTIME = false

  def change
    add_column :application_settings,
      :elasticsearch_indexed_file_size_limit_kb,
      :integer,
      null: false,
      default: 1024 # 1 MiB (units in KiB)
  end
end
