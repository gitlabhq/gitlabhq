# See http://doc.gitlab.com/ce/development/migration_style_guide.html
# for more information on how to write migrations for GitLab.

class AddAcceptedTermToUsers < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    change_table :users do |t|
      t.references :accepted_term,
                   null: true
    end
    add_concurrent_foreign_key :users, :application_setting_terms, column: :accepted_term_id
  end

  def down
    remove_foreign_key :users, column: :accepted_term_id
    remove_column :users, :accepted_term_id
  end
end
