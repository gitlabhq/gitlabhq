# frozen_string_literal: true

# See http://doc.gitlab.com/ce/development/migration_style_guide.html
# for more information on how to write migrations for GitLab.

class AddIndexToUsersPublicEmails < ActiveRecord::Migration[5.1]
  include Gitlab::Database::MigrationHelpers

  # Set this constant to true if this migration requires downtime.
  DOWNTIME = false

  disable_ddl_transaction!

  def up
    add_concurrent_index :users, [:public_email],
                         where: "public_email != ''"
  end

  def down
    remove_concurrent_index :users, [:public_email],
                         where: "public_email != ''"
  end
end
