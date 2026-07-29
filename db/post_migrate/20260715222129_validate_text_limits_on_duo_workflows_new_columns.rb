# frozen_string_literal: true

class ValidateTextLimitsOnDuoWorkflowsNewColumns < Gitlab::Database::Migration[2.3]
  milestone '19.3'

  disable_ddl_transaction!

  TABLE = :duo_workflows_workflows

  def up
    validate_text_limit TABLE, :agent_type
    validate_text_limit TABLE, :jsonl_sha256
    validate_text_limit TABLE, :idempotency_key
  end

  def down
    # no-op: validate_text_limit is not reversible
  end
end
