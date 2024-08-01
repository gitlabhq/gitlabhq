# frozen_string_literal: true

# See https://docs.gitlab.com/ee/development/migration_style_guide.html
# for more information on how to write migrations for GitLab.

class AddNamespacesO11yMetricsFk < Gitlab::Database::Migration[2.2]
  disable_ddl_transaction!
  milestone '17.3'

  def up
    add_concurrent_foreign_key :observability_metrics_issues_connections,
      :namespaces,
      column: :namespace_id,
      on_delete: :cascade
  end

  def down
    with_lock_retries do
      remove_foreign_key :observability_metrics_issues_connections, column: :namespace_id
    end
  end
end
