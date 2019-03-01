# frozen_string_literal: true

class AddExtraShasToCiPipelines < ActiveRecord::Migration[5.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  def change
    add_column :ci_pipelines, :source_sha, :binary
    add_column :ci_pipelines, :target_sha, :binary
  end
end
