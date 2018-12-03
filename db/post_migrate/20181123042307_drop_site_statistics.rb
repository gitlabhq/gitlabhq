# frozen_string_literal: true

# See http://doc.gitlab.com/ce/development/migration_style_guide.html
# for more information on how to write migrations for GitLab.

class DropSiteStatistics < ActiveRecord::Migration[5.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  def up
    drop_table :site_statistics
  end

  def down
    create_table :site_statistics do |t|
      t.integer :repositories_count, default: 0, null: false
    end

    execute('INSERT INTO site_statistics (id) VALUES(1)')
  end
end
