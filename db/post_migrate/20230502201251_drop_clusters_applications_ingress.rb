# frozen_string_literal: true

# See https://docs.gitlab.com/ee/development/migration_style_guide.html
# for more information on how to write migrations for GitLab.

class DropClustersApplicationsIngress < Gitlab::Database::Migration[2.1]
  def up
    drop_table :clusters_applications_ingress
  end

  # Based on init schema:
  # https://gitlab.com/gitlab-org/gitlab/-/blob/b237f836df215a4ada92b9406733e6cd2483ca2d/db/migrate/20181228175414_init_schema.rb#L704-L715
  # rubocop:disable Migration/SchemaAdditionMethodsNoPost
  # rubocop:disable Migration/Datetime
  def down
    create_table "clusters_applications_ingress", id: :serial, force: :cascade do |t|
      t.integer "cluster_id", null: false
      t.datetime "created_at", null: false
      t.datetime "updated_at", null: false
      t.integer "status", null: false
      t.integer "ingress_type", null: false
      t.string "version", null: false
      t.string "cluster_ip"
      t.text "status_reason"
      t.string "external_ip"
      t.string "external_hostname"
      t.index ["cluster_id"], name: "index_clusters_applications_ingress_on_cluster_id", unique: true
    end
  end
  # rubocop:enable Migration/SchemaAdditionMethodsNoPost
  # rubocop:enable Migration/Datetime
end
