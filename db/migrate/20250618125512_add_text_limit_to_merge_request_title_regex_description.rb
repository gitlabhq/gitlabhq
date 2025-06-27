# frozen_string_literal: true

class AddTextLimitToMergeRequestTitleRegexDescription < Gitlab::Database::Migration[2.3]
  milestone '18.2'
  disable_ddl_transaction!

  def up
    add_text_limit :project_settings, :merge_request_title_regex_description, 255
  end

  def down
    remove_text_limit :project_settings, :merge_request_title_regex_description
  end
end
