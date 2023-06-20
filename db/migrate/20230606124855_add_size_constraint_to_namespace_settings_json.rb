# frozen_string_literal: true

class AddSizeConstraintToNamespaceSettingsJson < Gitlab::Database::Migration[2.1]
  CONSTRAINT_NAME = 'default_branch_protection_defaults_size_constraint'

  disable_ddl_transaction!

  def up
    add_check_constraint :namespace_settings, 'octet_length(default_branch_protection_defaults::text) <= 1024',
      CONSTRAINT_NAME, validate: false
  end

  def down
    remove_check_constraint :namespace_settings, CONSTRAINT_NAME
  end
end
