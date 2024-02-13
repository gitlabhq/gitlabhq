# frozen_string_literal: true

class AddNameAndDescriptionToWebHooks < Gitlab::Database::Migration[2.2]
  milestone '16.9'

  # rubocop:disable Migration/AddLimitToTextColumns -- limit is added in
  # db/migrate/20240116162201_add_text_limit_to_web_hooks_attributes.rb
  def change
    add_column :web_hooks, :name, :text
    add_column :web_hooks, :description, :text
  end
  # rubocop:enable Migration/AddLimitToTextColumns
end
