# frozen_string_literal: true

class ReseedMergeTrainsEnabled < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    update_column_in_batches(:project_ci_cd_settings, :merge_trains_enabled, true) do |table, query|
      query.where(table[:merge_pipelines_enabled].eq(true))
    end
  end

  def down
    # no-op
  end
end
