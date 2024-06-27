# frozen_string_literal: true

class DropTableDastScannerProfilesTags < Gitlab::Database::Migration[2.2]
  milestone '17.2'
  disable_ddl_transaction!

  def up
    drop_table :dast_scanner_profiles_tags if table_exists? :dast_scanner_profiles_tags
  end

  def down
    unless table_exists?(:dast_scanner_profiles_tags)
      create_table :dast_scanner_profiles_tags do |t|
        t.bigint :dast_scanner_profile_id, null: false
        t.bigint :tag_id, null: false
        t.index :dast_scanner_profile_id, name: :i_dast_scanner_profiles_tags_on_scanner_profiles_id
        t.index :tag_id, name: :index_dast_scanner_profiles_tags_on_tag_id
      end
    end

    return if foreign_key_exists?(:dast_scanner_profiles_tags, :dast_scanner_profiles, name: :fk_rails_deb79b7f19)

    add_concurrent_foreign_key(
      :dast_scanner_profiles_tags,
      :dast_scanner_profiles,
      column: :dast_scanner_profile_id,
      name: :fk_rails_deb79b7f19)
  end
end
