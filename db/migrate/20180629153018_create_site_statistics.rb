class CreateSiteStatistics < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  def up
    create_table :site_statistics do |t|
      t.integer :repositories_count, default: 0, null: false
      t.integer :wikis_count, default: 0, null: false
    end

    execute('INSERT INTO site_statistics (id) VALUES(1)')
  end

  def down
    drop_table :site_statistics
  end
end
