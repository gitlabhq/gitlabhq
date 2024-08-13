# frozen_string_literal: true

class AddTmpIndexToNamespaceSettingsOnNewUserSignupsCap < Gitlab::Database::Migration[2.2]
  disable_ddl_transaction!

  milestone '17.3'

  TABLE = :namespace_settings
  COLUMN = :new_user_signups_cap
  INDEX_NAME = 'tmp_index_namespace_settings_on_new_user_signups_cap'

  def up
    add_concurrent_index TABLE, COLUMN, name: INDEX_NAME, where: 'new_user_signups_cap IS NOT NULL'
  end

  def down
    remove_concurrent_index_by_name TABLE, INDEX_NAME
  end
end
