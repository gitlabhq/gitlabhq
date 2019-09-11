# frozen_string_literal: true

# See http://doc.gitlab.com/ce/development/migration_style_guide.html
# for more information on how to write migrations for GitLab.

class AddStaticObjectTokenToUsers < ActiveRecord::Migration[5.2]
  DOWNTIME = false

  disable_ddl_transaction!

  def up
    add_column :users, :static_object_token, :string, limit: 255
  end

  def down
    remove_column :users, :static_object_token
  end
end
