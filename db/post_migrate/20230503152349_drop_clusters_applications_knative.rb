# frozen_string_literal: true

class DropClustersApplicationsKnative < Gitlab::Database::Migration[2.1]
  def up
    drop_table :clusters_applications_knative
  end

  # Based on init migration:
  # https://gitlab.com/gitlab-org/gitlab/-/blob/b237f836df215a4ada92b9406733e6cd2483ca2d/db/migrate/20181228175414_init_schema.rb#L730-L740
  def down
    create_table "clusters_applications_knative", id: :serial, force: :cascade do |t|
      t.integer "cluster_id", null: false
      t.datetime_with_timezone "created_at", null: false
      t.datetime_with_timezone "updated_at", null: false
      t.integer "status", null: false
      t.string "version", null: false
      t.string "hostname"
      t.text "status_reason"
      t.string "external_hostname"
      t.string "external_ip"
      t.index ["cluster_id"], name: "index_clusters_applications_knative_on_cluster_id", unique: true
    end
  end
end
