# frozen_string_literal: true

class DropParentConstraintsFromNotesArchived < Gitlab::Database::Migration[2.3]
  CONSTRAINT_NAMES = %w[
    check_notes_archived_has_parent
    check_82f260979e
  ].freeze

  disable_ddl_transaction!
  milestone '18.5'

  def up
    CONSTRAINT_NAMES.each do |constraint_name|
      remove_check_constraint(:notes_archived, constraint_name)
    end
  end

  def down
    with_lock_retries do
      execute <<~SQL
        ALTER TABLE notes_archived
        ADD CONSTRAINT check_notes_archived_has_parent
        CHECK (num_nonnulls(namespace_id, organization_id, project_id) >= 1)
        NOT VALID;
      SQL

      execute <<~SQL
        ALTER TABLE notes_archived
        ADD CONSTRAINT check_82f260979e
        CHECK (num_nonnulls(namespace_id, organization_id, project_id) >= 1);
      SQL
    end
  end
end
