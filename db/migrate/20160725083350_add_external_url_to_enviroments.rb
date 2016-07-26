class AddExternalUrlToEnviroments < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  def change
    add_column(:environments, :external_url, :string)
  end
end
