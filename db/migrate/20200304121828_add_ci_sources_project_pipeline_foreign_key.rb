# frozen_string_literal: true

class AddCiSourcesProjectPipelineForeignKey < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  def change
    with_lock_retries do
      add_foreign_key :ci_sources_projects, :ci_pipelines, column: :pipeline_id, on_delete: :cascade # rubocop:disable Migration/AddConcurrentForeignKey
    end
  end
end
