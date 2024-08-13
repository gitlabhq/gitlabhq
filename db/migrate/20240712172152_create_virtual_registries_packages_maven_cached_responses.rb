# frozen_string_literal: true

class CreateVirtualRegistriesPackagesMavenCachedResponses < Gitlab::Database::Migration[2.2]
  milestone '17.3'
  disable_ddl_transaction!

  TABLE_NAME = :virtual_registries_packages_maven_cached_responses

  def up
    with_lock_retries do
      create_table TABLE_NAME, if_not_exists: true do |t|
        t.references :group,
          null: false,
          index: { name: 'index_virtual_reg_pkgs_maven_cached_responses_on_group_id' },
          foreign_key: { to_table: :namespaces, on_delete: :cascade }
        t.references :upstream,
          null: false,
          index: false,
          foreign_key: { to_table: :virtual_registries_packages_maven_upstreams, on_delete: :nullify }
        t.datetime_with_timezone :upstream_checked_at, null: false, default: -> { 'NOW()' }
        t.datetime_with_timezone :downloaded_at, null: false, default: -> { 'NOW()' }
        t.timestamps_with_timezone null: false
        t.integer :file_store, null: false, default: 1
        t.integer :size, null: false
        t.integer :downloads_count, null: false, default: 1
        t.text :relative_path, null: false, limit: 255
        t.text :file, null: false, limit: 255
        t.text :object_storage_key, null: false, limit: 255
        t.text :upstream_etag, limit: 255
        t.text :content_type, limit: 255, null: false, default: 'application/octet-stream'
      end
    end

    add_concurrent_index(
      TABLE_NAME,
      [:upstream_id, :relative_path],
      unique: true,
      name: 'idx_vregs_pkgs_mvn_cached_resp_on_uniq_upstrm_id_and_rel_path'
    )

    constraint = check_constraint_name(TABLE_NAME.to_s, 'downloads_count', 'positive')
    add_check_constraint(TABLE_NAME, 'downloads_count > 0', constraint)
  end

  def down
    drop_table TABLE_NAME
  end
end
