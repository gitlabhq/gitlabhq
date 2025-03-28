# frozen_string_literal: true

class AddTextLimitToMergeRequestTitleRegex < Gitlab::Database::Migration[2.2]
  milestone '17.11'
  disable_ddl_transaction!

  def up
    add_text_limit :project_settings, :merge_request_title_regex, 255
  end

  def down
    remove_text_limit :project_settings, :merge_request_title_regex
  end
end
