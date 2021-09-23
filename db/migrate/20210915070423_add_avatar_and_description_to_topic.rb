# frozen_string_literal: true

class AddAvatarAndDescriptionToTopic < Gitlab::Database::Migration[1.0]
  # rubocop:disable Migration/AddLimitToTextColumns
  def up
    add_column :topics, :avatar, :text
    add_column :topics, :description, :text
  end
  # rubocop:enable Migration/AddLimitToTextColumns

  def down
    remove_column :topics, :avatar
    remove_column :topics, :description
  end
end
