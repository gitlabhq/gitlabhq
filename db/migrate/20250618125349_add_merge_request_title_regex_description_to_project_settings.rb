# frozen_string_literal: true

class AddMergeRequestTitleRegexDescriptionToProjectSettings < Gitlab::Database::Migration[2.3]
  milestone '18.2'

  def change
    # rubocop:disable Migration/AddLimitToTextColumns -- Limit is added in db/migrate/20250618125512_add_text_limit_to_merge_request_title_regex_description.rb
    add_column :project_settings, :merge_request_title_regex_description, :text, null: true
    # rubocop:enable Migration/AddLimitToTextColumns
  end
end
