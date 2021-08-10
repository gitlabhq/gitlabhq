# frozen_string_literal: true

class CreateAnalyticsCycleAnalyticsStageEventHashes < ActiveRecord::Migration[6.1]
  def change
    create_table :analytics_cycle_analytics_stage_event_hashes do |t|
      t.binary :hash_sha256
      t.index :hash_sha256, unique: true, name: 'index_cycle_analytics_stage_event_hashes_on_hash_sha_256'
    end
  end
end
