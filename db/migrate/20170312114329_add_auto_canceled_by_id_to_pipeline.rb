class AddAutoCanceledByIdToPipeline < ActiveRecord::Migration[4.2]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  def change
    add_column :ci_pipelines, :auto_canceled_by_id, :integer
  end
end
