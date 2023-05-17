# frozen_string_literal: true

# See https://docs.gitlab.com/ee/development/migration_style_guide.html
# for more information on how to write migrations for GitLab.

class DropClustersApplicationsRunners < Gitlab::Database::Migration[2.1]
  def up
    drop_table :clusters_applications_runners
  end

  # Based on init schema:
  # https://gitlab.com/gitlab-org/gitlab/-/blob/b237f836df215a4ada92b9406733e6cd2483ca2d/db/migrate/20181228175414_init_schema.rb#L752-L763
  # rubocop:disable Migration/SchemaAdditionMethodsNoPost
  def down
    create_table "clusters_applications_runners", id: :serial, force: :cascade do |t|
      t.integer "cluster_id", null: false
      t.integer "runner_id"
      t.integer "status", null: false
      t.datetime_with_timezone "created_at", null: false
      t.datetime_with_timezone "updated_at", null: false
      t.string "version", null: false
      t.text "status_reason"
      t.boolean "privileged", default: true, null: false
      t.index ["cluster_id"], name: "index_clusters_applications_runners_on_cluster_id", unique: true
      t.index ["runner_id"], name: "index_clusters_applications_runners_on_runner_id"
    end
  end
  # rubocop:enable Migration/SchemaAdditionMethodsNoPost
end
