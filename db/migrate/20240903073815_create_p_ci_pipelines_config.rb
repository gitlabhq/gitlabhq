# frozen_string_literal: true

class CreatePCiPipelinesConfig < Gitlab::Database::Migration[2.2]
  milestone '17.4'

  # rubocop:disable Migration/EnsureFactoryForTable -- No factory needed
  # rubocop:disable Migration/AddLimitToTextColumns -- keeps compatibility with existing table

  def change
    create_table(:p_ci_pipelines_config, primary_key: [:pipeline_id, :partition_id],
      options: 'PARTITION BY LIST (partition_id)') do |t|
      t.bigint :pipeline_id, null: false
      t.bigint :partition_id, null: false
      t.text :content, null: false
    end
  end
  # rubocop:enable Migration/EnsureFactoryForTable
  # rubocop:enable Migration/AddLimitToTextColumns
end
