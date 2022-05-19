# frozen_string_literal: true

class AddTitleToTopic < Gitlab::Database::Migration[1.0]
  # rubocop:disable Migration/AddLimitToTextColumns
  # limit is added in 20220331130726_add_text_limit_to_topics_title.rb
  def change
    add_column :topics, :title, :text
  end
  # rubocop:enable Migration/AddLimitToTextColumns
end
