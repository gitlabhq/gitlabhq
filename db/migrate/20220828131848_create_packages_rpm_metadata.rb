# frozen_string_literal: true

class CreatePackagesRpmMetadata < Gitlab::Database::Migration[2.0]
  disable_ddl_transaction!

  def up
    with_lock_retries do
      create_table :packages_rpm_metadata, id: false do |t|
        t.references :package,
                     primary_key: true,
                     default: nil,
                     index: true,
                     foreign_key: { to_table: :packages_packages, on_delete: :cascade },
                     type: :bigint
        t.text :release, default: '1', null: false, limit: 128
        t.text :summary, default: '', null: false, limit: 1000
        t.text :description, default: '', null: false, limit: 5000
        t.text :arch, default: '', null: false, limit: 255
        t.text :license, null: true, limit: 1000
        t.text :url, null: true, limit: 1000
      end
    end
  end

  def down
    with_lock_retries do
      drop_table :packages_rpm_metadata
    end
  end
end
