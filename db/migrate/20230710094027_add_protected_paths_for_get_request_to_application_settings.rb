# frozen_string_literal: true

class AddProtectedPathsForGetRequestToApplicationSettings < Gitlab::Database::Migration[2.1]
  CONSTRAINT_NAME = 'app_settings_protected_paths_max_length'

  disable_ddl_transaction!

  def up
    with_lock_retries do
      add_column :application_settings, :protected_paths_for_get_request,
        :text,
        array: true,
        default: [],
        null: false,
        if_not_exists: true
    end

    add_check_constraint :application_settings, 'CARDINALITY(protected_paths_for_get_request) <= 100', CONSTRAINT_NAME
  end

  def down
    with_lock_retries do
      remove_column :application_settings, :protected_paths_for_get_request, if_exists: true
    end
  end
end
