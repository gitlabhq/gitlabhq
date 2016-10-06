class AddStateToEnvironment < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  def change
    add_column :environments, :state, :string
  end
end
