# frozen_string_literal: true

class AddApplicationSettingsMaxDecompressionSizeConstraint < Gitlab::Database::Migration[2.1]
  CONSTRAINT_NAME = 'app_settings_max_decompressed_archive_size_positive'

  disable_ddl_transaction!

  def up
    add_check_constraint :application_settings, 'max_decompressed_archive_size >= 0', CONSTRAINT_NAME
  end

  def down
    remove_check_constraint :application_settings, CONSTRAINT_NAME
  end
end
