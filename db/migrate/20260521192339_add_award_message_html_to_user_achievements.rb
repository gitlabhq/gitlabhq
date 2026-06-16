# frozen_string_literal: true

class AddAwardMessageHtmlToUserAchievements < Gitlab::Database::Migration[2.3]
  milestone '19.1'

  def change
    add_column :user_achievements, :award_message_html, :text, null: true # rubocop:disable Migration/AddLimitToTextColumns -- cached markdown HTML derived from award_message which has a 200-char limit
    add_column :user_achievements, :cached_markdown_version, :integer, null: true
  end
end
