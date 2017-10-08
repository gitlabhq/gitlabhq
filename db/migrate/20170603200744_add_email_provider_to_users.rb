class AddEmailProviderToUsers < ActiveRecord::Migration[4.2]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  def change
    add_column :users, :email_provider, :string
  end
end
