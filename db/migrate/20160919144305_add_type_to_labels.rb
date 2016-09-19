class AddTypeToLabels < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  def change
    add_column :labels, :type, :string
  end
end
