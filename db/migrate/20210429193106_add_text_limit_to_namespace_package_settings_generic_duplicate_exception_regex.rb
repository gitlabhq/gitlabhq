# frozen_string_literal: true

class AddTextLimitToNamespacePackageSettingsGenericDuplicateExceptionRegex < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  disable_ddl_transaction!

  def up
    add_text_limit :namespace_package_settings, :generic_duplicate_exception_regex, 255
  end

  def down
    remove_text_limit :namespace_package_settings, :generic_duplicate_exception_regex
  end
end
