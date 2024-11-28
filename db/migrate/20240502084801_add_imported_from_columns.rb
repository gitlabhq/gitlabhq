# frozen_string_literal: true

class AddImportedFromColumns < Gitlab::Database::Migration[2.2]
  milestone '17.0'

  disable_ddl_transaction!

  def up
    with_lock_retries do
      add_column :design_management_designs,
        :imported_from, :integer, default: 0, null: false, limit: 2, if_not_exists: true
    end

    with_lock_retries do
      add_column :epics,
        :imported_from, :integer, default: 0, null: false, limit: 2, if_not_exists: true
    end

    with_lock_retries do
      add_column :events, # rubocop:disable Migration/PreventAddingColumns -- Legacy migration
        :imported_from, :integer, default: 0, null: false, limit: 2, if_not_exists: true
    end

    with_lock_retries do
      add_column :issues, # rubocop:disable Migration/PreventAddingColumns -- Legacy migration
        :imported_from, :integer, default: 0, null: false, limit: 2, if_not_exists: true
    end

    with_lock_retries do
      add_column :merge_requests, # rubocop:disable Migration/PreventAddingColumns -- Legacy migration
        :imported_from, :integer, default: 0, null: false, limit: 2, if_not_exists: true
    end

    with_lock_retries do
      add_column :notes, # rubocop:disable Migration/PreventAddingColumns -- Legacy migration
        :imported_from, :integer, default: 0, null: false, limit: 2, if_not_exists: true
    end

    with_lock_retries do
      add_column :resource_label_events, # rubocop:disable Migration/PreventAddingColumns -- Legacy migration
        :imported_from, :integer, default: 0, null: false, limit: 2, if_not_exists: true
    end

    with_lock_retries do
      add_column :resource_milestone_events,
        :imported_from, :integer, default: 0, null: false, limit: 2, if_not_exists: true
    end

    with_lock_retries do
      add_column :resource_state_events,
        :imported_from, :integer, default: 0, null: false, limit: 2, if_not_exists: true
    end

    with_lock_retries do
      add_column :snippets,
        :imported_from, :integer, default: 0, null: false, limit: 2, if_not_exists: true
    end

    with_lock_retries do
      add_column :temp_notes_backup,
        :imported_from, :integer, default: 0, null: false, limit: 2, if_not_exists: true
    end
  end

  def down
    with_lock_retries do
      remove_column :design_management_designs, :imported_from, :integer, if_exists: true
    end

    with_lock_retries do
      remove_column :epics,                     :imported_from, :integer, if_exists: true
    end

    with_lock_retries do
      remove_column :events,                    :imported_from, :integer, if_exists: true
    end

    with_lock_retries do
      remove_column :issues,                    :imported_from, :integer, if_exists: true
    end

    with_lock_retries do
      remove_column :merge_requests,            :imported_from, :integer, if_exists: true
    end

    with_lock_retries do
      remove_column :notes,                     :imported_from, :integer, if_exists: true
    end

    with_lock_retries do
      remove_column :resource_label_events,     :imported_from, :integer, if_exists: true
    end

    with_lock_retries do
      remove_column :resource_milestone_events, :imported_from, :integer, if_exists: true
    end

    with_lock_retries do
      remove_column :resource_state_events,     :imported_from, :integer, if_exists: true
    end

    with_lock_retries do
      remove_column :snippets,                  :imported_from, :integer, if_exists: true
    end

    with_lock_retries do
      remove_column :temp_notes_backup,         :imported_from, :integer, if_exists: true
    end
  end
end
