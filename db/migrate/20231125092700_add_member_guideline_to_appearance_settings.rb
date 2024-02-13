# frozen_string_literal: true

class AddMemberGuidelineToAppearanceSettings < Gitlab::Database::Migration[2.2]
  disable_ddl_transaction!
  milestone '16.9'

  def up
    # rubocop:disable Migration/AddLimitToTextColumns -- html caching field
    # limit is added in 20240130092700_add_text_limit_to_appearance_settings_member_guideline
    add_column :appearances, :member_guidelines, :text
    # html caching field without limit
    add_column :appearances, :member_guidelines_html, :text
    # rubocop:enable Migration/AddLimitToTextColumns -- html caching field
  end

  def down
    remove_column :appearances, :member_guidelines
    remove_column :appearances, :member_guidelines_html
  end
end
