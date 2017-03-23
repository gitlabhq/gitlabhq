class CreateContainerRepository < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  def change
    create_table :container_repositories do |t|
      t.integer :project_id
      t.string :path
    end
  end
end
