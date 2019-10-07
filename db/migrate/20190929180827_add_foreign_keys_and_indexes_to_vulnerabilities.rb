# frozen_string_literal: true

# See http://doc.gitlab.com/ce/development/migration_style_guide.html
# for more information on how to write migrations for GitLab.

class AddForeignKeysAndIndexesToVulnerabilities < ActiveRecord::Migration[5.2]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    add_concurrent_index :vulnerabilities, :milestone_id
    add_concurrent_foreign_key :vulnerabilities, :milestones, column: :milestone_id, on_delete: :nullify

    add_concurrent_index :vulnerabilities, :epic_id
    add_concurrent_foreign_key :vulnerabilities, :epics, column: :epic_id, on_delete: :nullify

    add_concurrent_index :vulnerabilities, :project_id
    add_concurrent_foreign_key :vulnerabilities, :projects, column: :project_id

    add_concurrent_index :vulnerabilities, :author_id
    add_concurrent_foreign_key :vulnerabilities, :users, column: :author_id, on_delete: :nullify

    add_concurrent_index :vulnerabilities, :updated_by_id
    add_concurrent_foreign_key :vulnerabilities, :users, column: :updated_by_id, on_delete: :nullify

    add_concurrent_index :vulnerabilities, :last_edited_by_id
    add_concurrent_foreign_key :vulnerabilities, :users, column: :last_edited_by_id, on_delete: :nullify

    add_concurrent_index :vulnerabilities, :closed_by_id
    add_concurrent_foreign_key :vulnerabilities, :users, column: :closed_by_id, on_delete: :nullify

    add_concurrent_index :vulnerabilities, :start_date_sourcing_milestone_id
    add_concurrent_foreign_key :vulnerabilities, :milestones, column: :start_date_sourcing_milestone_id, on_delete: :nullify

    add_concurrent_index :vulnerabilities, :due_date_sourcing_milestone_id
    add_concurrent_foreign_key :vulnerabilities, :milestones, column: :due_date_sourcing_milestone_id, on_delete: :nullify

    add_concurrent_index :vulnerability_occurrences, :vulnerability_id
    add_concurrent_foreign_key :vulnerability_occurrences, :vulnerabilities, column: :vulnerability_id, on_delete: :nullify
  end

  def down
    remove_foreign_key :vulnerability_occurrences, :vulnerabilities
    remove_concurrent_index :vulnerability_occurrences, :vulnerability_id

    remove_foreign_key :vulnerabilities, column: :due_date_sourcing_milestone_id
    remove_concurrent_index :vulnerabilities, :due_date_sourcing_milestone_id

    remove_foreign_key :vulnerabilities, column: :start_date_sourcing_milestone_id
    remove_concurrent_index :vulnerabilities, :start_date_sourcing_milestone_id

    remove_foreign_key :vulnerabilities, column: :closed_by_id
    remove_concurrent_index :vulnerabilities, :closed_by_id

    remove_foreign_key :vulnerabilities, column: :last_edited_by_id
    remove_concurrent_index :vulnerabilities, :last_edited_by_id

    remove_foreign_key :vulnerabilities, column: :updated_by_id
    remove_concurrent_index :vulnerabilities, :updated_by_id

    remove_foreign_key :vulnerabilities, column: :author_id
    remove_concurrent_index :vulnerabilities, :author_id

    remove_foreign_key :vulnerabilities, :projects
    remove_concurrent_index :vulnerabilities, :project_id

    remove_foreign_key :vulnerabilities, :epics
    remove_concurrent_index :vulnerabilities, :epic_id

    remove_foreign_key :vulnerabilities, :milestones
    remove_concurrent_index :vulnerabilities, :milestone_id
  end
end
