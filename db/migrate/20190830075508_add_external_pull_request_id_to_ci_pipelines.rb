# frozen_string_literal: true

class AddExternalPullRequestIdToCiPipelines < ActiveRecord::Migration[5.2]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  def up
    add_column :ci_pipelines, :external_pull_request_id, :bigint
  end

  def down
    remove_column :ci_pipelines, :external_pull_request_id
  end
end
