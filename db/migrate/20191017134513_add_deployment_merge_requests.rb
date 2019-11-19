# frozen_string_literal: true

class AddDeploymentMergeRequests < ActiveRecord::Migration[5.2]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  def change
    create_table :deployment_merge_requests, id: false do |t|
      t.references(
        :deployment,
        foreign_key: { on_delete: :cascade },
        type: :integer,
        index: false,
        null: false
      )

      t.references(
        :merge_request,
        foreign_key: { on_delete: :cascade },
        type: :integer,
        index: true,
        null: false
      )

      t.index(
        [:deployment_id, :merge_request_id],
        unique: true,
        name: 'idx_deployment_merge_requests_unique_index'
      )
    end
  end
end
