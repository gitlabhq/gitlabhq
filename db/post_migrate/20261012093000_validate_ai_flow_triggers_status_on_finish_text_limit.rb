# frozen_string_literal: true

class ValidateAiFlowTriggersStatusOnFinishTextLimit < Gitlab::Database::Migration[2.4]
  milestone '19.6'

  disable_ddl_transaction!

  def up
    validate_text_limit :ai_flow_triggers, :status_on_finish
  end

  def down
    # no-op
  end
end
