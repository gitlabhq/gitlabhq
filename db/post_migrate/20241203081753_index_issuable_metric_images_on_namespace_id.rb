# frozen_string_literal: true

class IndexIssuableMetricImagesOnNamespaceId < Gitlab::Database::Migration[2.2]
  milestone '17.7'
  disable_ddl_transaction!

  INDEX_NAME = 'index_issuable_metric_images_on_namespace_id'

  def up
    add_concurrent_index :issuable_metric_images, :namespace_id, name: INDEX_NAME
  end

  def down
    remove_concurrent_index_by_name :issuable_metric_images, INDEX_NAME
  end
end
