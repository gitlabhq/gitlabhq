# frozen_string_literal: true

class AddTextLimitToAppearanceSettingsMemberGuideline < Gitlab::Database::Migration[2.2]
  disable_ddl_transaction!
  milestone '16.9'

  def up
    add_text_limit :appearances, :member_guidelines, 4096
  end

  def down
    remove_text_limit :sprints, :extended_title
  end
end
