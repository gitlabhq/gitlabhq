# frozen_string_literal: true

class UpdateProtectMergeRequestPipelinesDefaultToTrue < Gitlab::Database::Migration[2.3]
  milestone '18.1'

  def change
    change_column_default :project_settings, :protect_merge_request_pipelines, from: false, to: true
  end
end
