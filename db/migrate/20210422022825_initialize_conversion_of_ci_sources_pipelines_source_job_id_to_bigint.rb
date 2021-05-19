# frozen_string_literal: true

class InitializeConversionOfCiSourcesPipelinesSourceJobIdToBigint < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  def up
    # Foreign key that references ci_builds.id
    initialize_conversion_of_integer_to_bigint :ci_sources_pipelines, :source_job_id
  end

  def down
    trigger_name = rename_trigger_name(:ci_sources_pipelines, :source_job_id, :source_job_id_convert_to_bigint)

    remove_rename_triggers :ci_sources_pipelines, trigger_name

    remove_column :ci_sources_pipelines, :source_job_id_convert_to_bigint
  end
end
