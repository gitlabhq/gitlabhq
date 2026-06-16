# frozen_string_literal: true

class AddIssuableMetricImageUploadStatesNamespaceIdShardingKeyTrigger < Gitlab::Database::Migration[2.3]
  milestone '19.1'

  def up
    install_sharding_key_assignment_trigger(
      table: :issuable_metric_image_upload_states,
      sharding_key: :namespace_id,
      parent_table: :issuable_metric_image_uploads,
      parent_sharding_key: :namespace_id,
      foreign_key: :issuable_metric_image_upload_id
    )
  end

  def down
    remove_sharding_key_assignment_trigger(
      table: :issuable_metric_image_upload_states,
      sharding_key: :namespace_id,
      parent_table: :issuable_metric_image_uploads,
      parent_sharding_key: :namespace_id,
      foreign_key: :issuable_metric_image_upload_id
    )
  end
end
