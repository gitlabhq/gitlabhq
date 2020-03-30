# frozen_string_literal: true

# See http://doc.gitlab.com/ce/development/migration_style_guide.html
# for more information on how to write migrations for GitLab.

class AddRoleToUsers < ActiveRecord::Migration[5.2]
  DOWNTIME = false

  def change
    add_column :users, :role, :smallint # rubocop:disable Migration/AddColumnsToWideTables
  end
end
