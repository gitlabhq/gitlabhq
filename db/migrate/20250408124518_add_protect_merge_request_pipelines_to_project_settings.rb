# frozen_string_literal: true

class AddProtectMergeRequestPipelinesToProjectSettings < Gitlab::Database::Migration[2.2]
  milestone '17.11'

  def change
    add_column :project_settings, :protect_merge_request_pipelines, :boolean, null: false, default: false
  end
end
