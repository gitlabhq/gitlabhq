class AddRunnersTokenToGroups < ActiveRecord::Migration[4.2]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  def change
    add_column :namespaces, :runners_token, :string
  end
end
