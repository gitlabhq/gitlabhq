# frozen_string_literal: true

class AddIssuableMetricImagesNamespaceIdNotNull < Gitlab::Database::Migration[2.3]
  milestone '18.0'
  disable_ddl_transaction!

  def up
    add_not_null_constraint :issuable_metric_images, :namespace_id
  end

  def down
    remove_not_null_constraint :issuable_metric_images, :namespace_id
  end
end
