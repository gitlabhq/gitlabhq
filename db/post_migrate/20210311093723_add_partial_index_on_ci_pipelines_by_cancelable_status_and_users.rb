# frozen_string_literal: true

class AddPartialIndexOnCiPipelinesByCancelableStatusAndUsers < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false
  INDEX_NAME = 'index_ci_pipelines_on_user_id_and_id_and_cancelable_status'
  INDEX_FILTER_CONDITION = <<~SQL
    ((status)::text = ANY (
      ARRAY[
        ('running'::character varying)::text,
        ('waiting_for_resource'::character varying)::text,
        ('preparing'::character varying)::text,
        ('pending'::character varying)::text,
        ('created'::character varying)::text,
        ('scheduled'::character varying)::text
      ]
    ))
  SQL

  disable_ddl_transaction!

  def up
    add_concurrent_index :ci_pipelines, [:user_id, :id], where: INDEX_FILTER_CONDITION, name: INDEX_NAME
  end

  def down
    remove_concurrent_index_by_name :ci_pipelines, INDEX_NAME
  end
end
