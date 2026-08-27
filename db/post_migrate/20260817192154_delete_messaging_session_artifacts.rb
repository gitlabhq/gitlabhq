# frozen_string_literal: true

class DeleteMessagingSessionArtifacts < Gitlab::Database::Migration[2.3]
  restrict_gitlab_migration gitlab_schema: :gitlab_main_org
  milestone '19.4'

  disable_ddl_transaction!

  BATCH_SIZE = 1_000

  PRIVATE_ADAPTER_KEYS = %w[slack].freeze

  def up
    artifacts = define_batchable_model('duo_workflow_session_artifacts', connection: connection)
    workflows = define_batchable_model('duo_workflows_workflows', connection: connection)

    artifacts.each_batch(of: BATCH_SIZE) do |batch|
      private_workflow_ids = workflows
        .where(id: batch.select(:workflow_id))
        .where("(messaging_callback_context ->> 'adapter') IN (?)", PRIVATE_ADAPTER_KEYS)
        .select(:id)

      batch.where(workflow_id: private_workflow_ids).delete_all
    end
  end

  def down
    # no-op
  end
end
