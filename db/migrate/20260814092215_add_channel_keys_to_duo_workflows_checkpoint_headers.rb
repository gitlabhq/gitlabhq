# frozen_string_literal: true

class AddChannelKeysToDuoWorkflowsCheckpointHeaders < Gitlab::Database::Migration[2.3]
  milestone '19.4'

  disable_ddl_transaction!

  CONSTRAINT_NAME = 'check_duo_wf_checkpoint_headers_channel_keys_cardinality'

  # Blobs are an append-only log that cannot express a channel deletion, so the
  # reconstructed key set is the union of every channel ever written. This column
  # records the live membership. NULL means a row written before the column existed.
  def up
    add_column :p_duo_workflows_checkpoint_headers, :channel_keys, :text, array: true, if_not_exists: true

    # A checkpoint holds one key per flow state key plus one `branch:to:<node>` per
    # node armed for the next step, so the count tracks the flow's node count. The
    # largest shipped flow builds ~20 nodes; 100 leaves room for larger custom flows.
    add_check_constraint(
      :p_duo_workflows_checkpoint_headers,
      'cardinality(channel_keys) <= 100',
      CONSTRAINT_NAME
    )
  end

  def down
    remove_column :p_duo_workflows_checkpoint_headers, :channel_keys, if_exists: true
  end
end
