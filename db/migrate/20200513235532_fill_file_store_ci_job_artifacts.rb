# frozen_string_literal: true

class FillFileStoreCiJobArtifacts < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    # rubocop:disable Migration/UpdateLargeTable
    update_column_in_batches(:ci_job_artifacts, :file_store, 1) do |table, query|
      query.where(table[:file_store].eq(nil))
    end
    # rubocop:enable Migration/UpdateLargeTable
  end

  def down
    # no-op
  end
end
