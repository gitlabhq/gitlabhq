# frozen_string_literal: true

class RemoveForeignKeyInClustersApplicationsElasticStacks < Gitlab::Database::Migration[2.0]
  disable_ddl_transaction!

  def up
    with_lock_retries do
      remove_foreign_key_if_exists(:clusters_applications_elastic_stacks, column: :cluster_id)
    end
  end

  def down
    add_concurrent_foreign_key :clusters_applications_elastic_stacks, :clusters,
      column: :cluster_id, on_delete: :cascade, name: 'fk_rails_026f219f46'
  end
end
