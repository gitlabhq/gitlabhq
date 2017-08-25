class AddStatusToCiStages < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  def change
    add_column :ci_stages, :status, :integer
  end
end
