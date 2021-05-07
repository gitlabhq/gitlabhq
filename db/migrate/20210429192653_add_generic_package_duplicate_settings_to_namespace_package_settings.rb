# frozen_string_literal: true

class AddGenericPackageDuplicateSettingsToNamespacePackageSettings < ActiveRecord::Migration[6.0]
  # rubocop:disable Migration/AddLimitToTextColumns
  # limit is added in 20210429193106_add_text_limit_to_namespace_package_settings_generic_duplicate_exception_regex
  def change
    add_column :namespace_package_settings, :generic_duplicates_allowed, :boolean, null: false, default: true
    add_column :namespace_package_settings, :generic_duplicate_exception_regex, :text, null: false, default: ''
  end
  # rubocop:enable Migration/AddLimitToTextColumns
end
