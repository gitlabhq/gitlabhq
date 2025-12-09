# frozen_string_literal: true

class AddNotNullConstraintOnIssuableMetricImageUploadsShardingKey < Gitlab::Database::Migration[2.3]
  disable_ddl_transaction!
  milestone '18.7'

  def up
    add_not_null_constraint(:issuable_metric_image_uploads, :namespace_id)
  end

  def down
    remove_not_null_constraint(:issuable_metric_image_uploads, :namespace_id)
  end
end
