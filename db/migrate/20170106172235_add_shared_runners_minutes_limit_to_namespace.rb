class AddSharedRunnersMinutesLimitToNamespace < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  def change
    add_column :namespaces, :shared_runners_minutes_limit, :integer
  end
end
