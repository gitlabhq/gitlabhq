# frozen_string_literal: true

class AddProfileImageGuidelinesToAppearances < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    add_column :appearances, :profile_image_guidelines, :text, null: true
    add_column :appearances, :profile_image_guidelines_html, :text, null: true # rubocop:disable Migration/AddLimitToTextColumns

    add_text_limit :appearances, :profile_image_guidelines, 4096, constraint_name: 'appearances_profile_image_guidelines'
  end

  def down
    remove_column :appearances, :profile_image_guidelines
    remove_column :appearances, :profile_image_guidelines_html
  end
end
