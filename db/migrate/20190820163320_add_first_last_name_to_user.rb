# frozen_string_literal: true

# See http://doc.gitlab.com/ce/development/migration_style_guide.html
# for more information on how to write migrations for GitLab.

class AddFirstLastNameToUser < ActiveRecord::Migration[5.2]
  # Set this constant to true if this migration requires downtime.
  DOWNTIME = false

  def change
    add_column(:users, :first_name, :string, null: true, limit: 255)
    add_column(:users, :last_name, :string, null: true, limit: 255)
  end
end
