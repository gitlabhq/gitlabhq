# frozen_string_literal: true

class DropClustersApplicationsCilium < Gitlab::Database::Migration[2.1]
  def up
    drop_table :clusters_applications_cilium
  end

  # Based on original migration:
  # https://gitlab.com/gitlab-org/gitlab/-/blob/b237f836df215a4ada92b9406733e6cd2483ca2d/db/migrate/20200615234047_create_clusters_applications_cilium.rb
  def down
    create_table :clusters_applications_cilium do |t|
      t.references :cluster, null: false, index: { unique: true }
      t.timestamps_with_timezone null: false
      t.integer :status, null: false
      t.text :status_reason # rubocop:disable Migration/AddLimitToTextColumns
    end
  end
end
