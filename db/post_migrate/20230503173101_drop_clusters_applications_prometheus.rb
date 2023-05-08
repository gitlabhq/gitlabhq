# frozen_string_literal: true

# See https://docs.gitlab.com/ee/development/migration_style_guide.html
# for more information on how to write migrations for GitLab.

class DropClustersApplicationsPrometheus < Gitlab::Database::Migration[2.1]
  def up
    drop_table :clusters_applications_prometheus
  end

  # Based on init schema:
  # https://gitlab.com/gitlab-org/gitlab/-/blob/b237f836df215a4ada92b9406733e6cd2483ca2d/db/migrate/20181228175414_init_schema.rb#L742-L750
  # rubocop:disable Migration/SchemaAdditionMethodsNoPost
  def down
    create_table "clusters_applications_prometheus", id: :serial, force: :cascade do |t|
      t.integer "cluster_id", null: false
      t.integer "status", null: false
      t.string "version", null: false
      t.text "status_reason"
      t.datetime_with_timezone "created_at", null: false
      t.datetime_with_timezone "updated_at", null: false
      t.index ["cluster_id"], name: "index_clusters_applications_prometheus_on_cluster_id", unique: true
      t.datetime_with_timezone "last_update_started_at"
      t.string "encrypted_alert_manager_token"
      t.string "encrypted_alert_manager_token_iv"
      t.boolean "healthy"
    end
  end
  # rubocop:enable Migration/SchemaAdditionMethodsNoPost
end
