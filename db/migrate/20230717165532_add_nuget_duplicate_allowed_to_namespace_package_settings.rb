# frozen_string_literal: true

class AddNugetDuplicateAllowedToNamespacePackageSettings < Gitlab::Database::Migration[2.1]
  disable_ddl_transaction!

  def up
    with_lock_retries do
      add_column :namespace_package_settings, :nuget_duplicates_allowed, :boolean, default: true, null: false,
        if_not_exists: true
      add_column :namespace_package_settings, :nuget_duplicate_exception_regex, :text, default: '', null: false,
        if_not_exists: true
    end

    add_text_limit :namespace_package_settings, :nuget_duplicate_exception_regex, 255
  end

  def down
    with_lock_retries do
      remove_column :namespace_package_settings, :nuget_duplicates_allowed, if_exists: true
      remove_column :namespace_package_settings, :nuget_duplicate_exception_regex, if_exists: true
    end
  end
end
