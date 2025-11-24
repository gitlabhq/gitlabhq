# frozen_string_literal: true

class AddCompanyToUserDetails < Gitlab::Database::Migration[2.3]
  milestone '18.7'

  TABLE = :user_details
  OLD_COLUMN = :organization
  NEW_COLUMN = :company
  TRIGGER_NAME = 'trigger_c48e4298f362'

  def up
    check_trigger_permissions!(TABLE)

    # rubocop:disable Migration/AddLimitToTextColumns -- See db/migrate/20251117160950_add_text_limit_to_user_detail_company.rb
    add_column TABLE, :company, :text, default: '', null: false, if_not_exists: true
    # rubocop:enable Migration/AddLimitToTextColumns
    install_rename_triggers(TABLE, OLD_COLUMN, NEW_COLUMN, trigger_name: TRIGGER_NAME)
  end

  def down
    check_trigger_permissions!(TABLE)

    remove_rename_triggers(TABLE, TRIGGER_NAME)

    remove_column TABLE, NEW_COLUMN, if_exists: true
  end
end
