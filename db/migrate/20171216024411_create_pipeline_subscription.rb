class CreatePipelineSubscription < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  def up
    create_table :ci_pipeline_subscriptions do |t|
      t.references :ci_pipeline, index: true, foreign_key: true
      t.references :user, index: true, foreign_key: true
    end
  end

  def down
    drop_table :ci_pipeline_subscriptions
  end
end
