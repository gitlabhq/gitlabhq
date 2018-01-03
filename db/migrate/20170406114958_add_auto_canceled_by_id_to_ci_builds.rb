class AddAutoCanceledByIdToCiBuilds < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  def change
    add_column :ci_builds, :auto_canceled_by_id, :integer
  end
end
