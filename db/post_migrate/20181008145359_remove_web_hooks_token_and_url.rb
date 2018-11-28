class RemoveWebHooksTokenAndUrl < ActiveRecord::Migration[4.2]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  def change
    remove_column :web_hooks, :token, :string
    remove_column :web_hooks, :url, :string, limit: 2000
  end
end
