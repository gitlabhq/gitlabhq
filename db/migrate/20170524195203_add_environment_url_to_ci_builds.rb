class AddEnvironmentUrlToCiBuilds < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  def change
    add_column(:ci_builds, :environment_url, :string)
  end
end
