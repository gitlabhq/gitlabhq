# frozen_string_literal: true

class AddTextLimitToTopicsDescriptionAndAvatar < Gitlab::Database::Migration[1.0]
  disable_ddl_transaction!

  def up
    add_text_limit :topics, :description, 1024
    add_text_limit :topics, :avatar, 255
  end

  def down
    remove_text_limit :topics, :avatar
    remove_text_limit :topics, :description
  end
end
