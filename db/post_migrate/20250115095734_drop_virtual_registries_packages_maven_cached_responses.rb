# frozen_string_literal: true

class DropVirtualRegistriesPackagesMavenCachedResponses < Gitlab::Database::Migration[2.2]
  milestone '17.9'

  disable_ddl_transaction!

  TABLE_NAME = :virtual_registries_packages_maven_cached_responses

  def up
    drop_table(TABLE_NAME) if table_exists?(TABLE_NAME)
  end

  def down
    return if table_exists?(TABLE_NAME)

    create_table TABLE_NAME, if_not_exists: true do |t|
      t.bigint :group_id, null: false
      t.bigint :upstream_id
      t.datetime_with_timezone :upstream_checked_at, null: false, default: -> { 'NOW()' }
      t.datetime_with_timezone :downloaded_at, null: false, default: -> { 'NOW()' }
      t.timestamps_with_timezone null: false
      t.integer :file_store, null: false, default: 1
      t.integer :size, null: false
      t.text :relative_path, null: false, limit: 255
      t.text :file, null: false, limit: 255
      t.text :object_storage_key, null: false, limit: 255
      t.text :upstream_etag, limit: 255
      t.text :content_type, limit: 255, null: false, default: 'application/octet-stream'
      t.integer :status, null: false, default: 0, limit: 2
      t.text :file_final_path
      t.binary :file_md5
      t.binary :file_sha1, null: false
    end

    add_text_limit TABLE_NAME, :file_final_path, 1024

    add_concurrent_index(
      TABLE_NAME,
      [:upstream_id, :relative_path],
      unique: true,
      name: :idx_vregs_pkgs_mvn_cached_resp_on_uniq_default_upt_id_relpath,
      where: 'status = 0' # status: :default
    )
    add_concurrent_index(
      TABLE_NAME,
      [:upstream_id, :status, :id],
      name: :idx_vregs_pkgs_mvn_cached_resp_on_upst_id_status_id
    )
    add_concurrent_index(
      TABLE_NAME,
      %i[group_id status],
      name: :idx_vreg_pkgs_maven_cached_responses_on_group_id_status
    )

    add_concurrent_index(
      TABLE_NAME,
      :relative_path,
      using: :gin,
      opclass: :gin_trgm_ops,
      name: :idx_vreg_pkgs_maven_cached_responses_on_relative_path_trigram
    )
  end
end
