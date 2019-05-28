# frozen_string_literal: true

# See http://doc.gitlab.com/ce/development/migration_style_guide.html
# for more information on how to write migrations for GitLab.

class AddRemoveAtIndexToPagesDomains < ActiveRecord::Migration[5.0]
  include Gitlab::Database::MigrationHelpers
  DOWNTIME = false

  disable_ddl_transaction!

  def up
    add_concurrent_index :pages_domains, :remove_at
  end

  def down
    remove_concurrent_index :pages_domains, :remove_at
  end
end
