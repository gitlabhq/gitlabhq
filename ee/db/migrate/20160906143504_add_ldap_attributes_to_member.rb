# See http://doc.gitlab.com/ce/development/migration_style_guide.html
# for more information on how to write migrations for GitLab.

class AddLdapAttributesToMember < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers
  disable_ddl_transaction!

  DOWNTIME = false

  def up
    add_column_with_default :members, :ldap, :boolean, default: false, allow_null: false
    add_column_with_default :members, :override, :boolean, default: false, allow_null: false
  end

  def down
    remove_column :members, :ldap
    remove_column :members, :override
  end
end
