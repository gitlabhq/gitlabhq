# frozen_string_literal: true

# See https://docs.gitlab.com/ee/development/migration_style_guide.html
# for more information on how to write migrations for GitLab.

class DropClustersApplicationsJupyter < Gitlab::Database::Migration[2.1]
  def up
    drop_table :clusters_applications_jupyter
  end

  # Based on init schema:
  # https://gitlab.com/gitlab-org/gitlab/-/blob/b237f836df215a4ada92b9406733e6cd2483ca2d/db/migrate/20181228175414_init_schema.rb#L717-L728
  # rubocop:disable Migration/SchemaAdditionMethodsNoPost
  def down
    create_table "clusters_applications_jupyter", id: :serial, force: :cascade do |t|
      t.integer "cluster_id", null: false
      t.integer "oauth_application_id"
      t.integer "status", null: false
      t.string "version", null: false
      t.string "hostname"
      t.datetime_with_timezone "created_at", null: false
      t.datetime_with_timezone "updated_at", null: false
      t.text "status_reason"
      t.index ["cluster_id"], name: "index_clusters_applications_jupyter_on_cluster_id", unique: true
      t.index ["oauth_application_id"], name: "index_clusters_applications_jupyter_on_oauth_application_id"
    end
  end
  # rubocop:enable Migration/SchemaAdditionMethodsNoPost
end
