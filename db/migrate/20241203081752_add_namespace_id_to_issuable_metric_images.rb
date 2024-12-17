# frozen_string_literal: true

class AddNamespaceIdToIssuableMetricImages < Gitlab::Database::Migration[2.2]
  milestone '17.7'

  def change
    add_column :issuable_metric_images, :namespace_id, :bigint
  end
end
