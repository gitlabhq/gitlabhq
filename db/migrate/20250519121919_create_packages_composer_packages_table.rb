# frozen_string_literal: true

class CreatePackagesComposerPackagesTable < Gitlab::Database::Migration[2.3]
  milestone '18.1'

  TABLE_NAME = :packages_composer_packages

  def up
    create_table TABLE_NAME, if_not_exists: true, id: false do |t|
      t.bigint :id, null: false, default: -> { "nextval('packages_packages_id_seq')" }, primary_key: true
      t.bigint :project_id, null: false
      t.bigint :creator_id
      t.timestamps_with_timezone
      t.datetime_with_timezone :last_downloaded_at
      t.integer :status, null: false, default: 0, limit: 2
      t.text :name, null: false # rubocop:disable Migration/AddLimitToTextColumns -- The source `packages_packages` table has no length limits.
      t.text :version # rubocop:disable Migration/AddLimitToTextColumns -- The source `packages_packages` table has no length limits.
      t.binary :target_sha
      t.binary :version_cache_sha
      t.text :status_message, limit: 255
      t.jsonb :composer_json, null: false, default: {}

      t.index :project_id, name: :idx_pkgs_composer_pkgs_on_project_id
      t.index :creator_id, name: :idx_pkgs_composer_pkgs_on_creator_id
    end
  end

  def down
    drop_table TABLE_NAME, if_exists: true
  end
end
