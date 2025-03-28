# frozen_string_literal: true

class AddMergeRequestTitleRegexToProjectSettings < Gitlab::Database::Migration[2.2]
  milestone '17.11'

  def change
    # rubocop:disable Migration/AddLimitToTextColumns -- Limit is added in db/migrate/20250317054045_add_text_limit_to_merge_request_title_regex.rb
    add_column :project_settings, :merge_request_title_regex, :text, null: true
    # rubocop:enable Migration/AddLimitToTextColumns
  end
end
