# frozen_string_literal: true
class RemoveElasticExperimentalIndexerFromApplicationSettings < ActiveRecord::Migration[6.0]
  DOWNTIME = false

  def change
    remove_column :application_settings, :elasticsearch_experimental_indexer, :boolean
  end
end
