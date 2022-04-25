# frozen_string_literal: true

class AddNullifyBuildDataTriggerOnMergeRequestMetrics < Gitlab::Database::Migration[1.0]
  include Gitlab::Database::SchemaHelpers

  TABLE_NAME = 'merge_request_metrics'
  FUNCTION_NAME = 'nullify_merge_request_metrics_build_data'
  TRIGGER_NAME = 'nullify_merge_request_metrics_build_data_on_update'

  def up
    create_trigger_function(FUNCTION_NAME) do
      <<~SQL
        IF (OLD.pipeline_id IS NOT NULL) AND (NEW.pipeline_id IS NULL) THEN
          NEW.latest_build_started_at = NULL;
          NEW.latest_build_finished_at = NULL;
        END IF;
        RETURN NEW;
      SQL
    end

    create_trigger(TABLE_NAME, TRIGGER_NAME, FUNCTION_NAME, fires: 'BEFORE UPDATE')
  end

  def down
    drop_trigger(TABLE_NAME, TRIGGER_NAME)
    drop_function(FUNCTION_NAME)
  end
end
