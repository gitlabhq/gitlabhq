# frozen_string_literal: true

# See http://doc.gitlab.com/ce/development/migration_style_guide.html
# for more information on how to write migrations for GitLab.

class AddTimelogSpentAtIndex < ActiveRecord::Migration[5.2]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    add_concurrent_index :timelogs, :spent_at, where: 'spent_at IS NOT NULL'
  end

  def down
    remove_concurrent_index :timelogs, :spent_at, where: 'spent_at IS NOT NULL'
  end
end
