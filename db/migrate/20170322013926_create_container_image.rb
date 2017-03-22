class CreateContainerImage < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  def change
    create_table :container_images do |t|
      t.integer :project_id
      t.string :name
      t.string :path
    end
  end
end
