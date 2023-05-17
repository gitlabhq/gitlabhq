# frozen_string_literal: true

# See https://docs.gitlab.com/ee/development/migration_style_guide.html
# for more information on how to write migrations for GitLab.

class DropClustersApplicationsHelm < Gitlab::Database::Migration[2.1]
  def up
    drop_table :clusters_applications_helm
  end

  # Based on init schema:
  # https://gitlab.com/gitlab-org/gitlab/-/blob/b237f836df215a4ada92b9406733e6cd2483ca2d/db/migrate/20181228175414_init_schema.rb#L691-L702
  # rubocop:disable Migration/SchemaAdditionMethodsNoPost
  # rubocop:disable Migration/Datetime
  def down
    create_table "clusters_applications_helm", id: :serial, force: :cascade do |t|
      t.integer "cluster_id", null: false
      t.datetime "created_at", null: false
      t.datetime "updated_at", null: false
      t.integer "status", null: false
      t.string "version", null: false
      t.text "status_reason"
      t.text "encrypted_ca_key"
      t.text "encrypted_ca_key_iv"
      t.text "ca_cert"
      t.index ["cluster_id"], name: "index_clusters_applications_helm_on_cluster_id", unique: true
    end
  end
  # rubocop:enable Migration/SchemaAdditionMethodsNoPost
  # rubocop:enable Migration/Datetime
end
