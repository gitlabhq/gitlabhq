# frozen_string_literal: true

class CreatePackagesNpmMetadata < Gitlab::Database::Migration[1.0]
  disable_ddl_transaction!

  def up
    with_lock_retries do
      create_table :packages_npm_metadata, id: false do |t|
        t.references :package, primary_key: true, default: nil, index: false, foreign_key: { to_table: :packages_packages, on_delete: :cascade }, type: :bigint
        t.jsonb :package_json, default: {}, null: false

        t.check_constraint 'char_length(package_json::text) < 20000'
      end
    end
  end

  def down
    with_lock_retries do
      drop_table :packages_npm_metadata
    end
  end
end
