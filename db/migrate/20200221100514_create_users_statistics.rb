# frozen_string_literal: true

class CreateUsersStatistics < ActiveRecord::Migration[6.0]
  DOWNTIME = false

  def change
    create_table :users_statistics do |t|
      t.timestamps_with_timezone null: false
      t.integer :without_groups_and_projects, null: false, default: 0
      t.integer :with_highest_role_guest, null: false, default: 0
      t.integer :with_highest_role_reporter, null: false, default: 0
      t.integer :with_highest_role_developer, null: false, default: 0
      t.integer :with_highest_role_maintainer, null: false, default: 0
      t.integer :with_highest_role_owner, null: false, default: 0
      t.integer :bots, null: false, default: 0
      t.integer :blocked, null: false, default: 0
    end
  end
end
