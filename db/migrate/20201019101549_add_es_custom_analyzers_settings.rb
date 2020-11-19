# frozen_string_literal: true

class AddEsCustomAnalyzersSettings < ActiveRecord::Migration[6.0]
  DOWNTIME = false

  def change
    add_column :application_settings, :elasticsearch_analyzers_smartcn_enabled, :bool, null: false, default: false
    add_column :application_settings, :elasticsearch_analyzers_smartcn_search, :bool, null: false, default: false
    add_column :application_settings, :elasticsearch_analyzers_kuromoji_enabled, :bool, null: false, default: false
    add_column :application_settings, :elasticsearch_analyzers_kuromoji_search, :bool, null: false, default: false
  end
end
