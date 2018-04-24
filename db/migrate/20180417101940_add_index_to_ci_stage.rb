class AddIndexToCiStage < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  def change
    add_column :ci_stages, :priority, :integer
  end
end
