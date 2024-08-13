# frozen_string_literal: true

class AddProjectIdToMergeRequestUserMentions < Gitlab::Database::Migration[2.2]
  milestone '17.3'

  def change
    add_column :merge_request_user_mentions, :project_id, :bigint
  end
end
