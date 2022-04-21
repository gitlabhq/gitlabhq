# frozen_string_literal: true

class AddTextLimitToTopicsTitle < Gitlab::Database::Migration[1.0]
  disable_ddl_transaction!

  def up
    add_text_limit :topics, :title, 255
  end

  def down
    remove_text_limit :topics, :title
  end
end
