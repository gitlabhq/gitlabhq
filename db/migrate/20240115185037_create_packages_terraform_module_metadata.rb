# frozen_string_literal: true

class CreatePackagesTerraformModuleMetadata < Gitlab::Database::Migration[2.2]
  milestone '16.9'

  def change
    create_table :packages_terraform_module_metadata, id: false do |t|
      t.timestamps_with_timezone null: false

      t.references :package,
        primary_key: true,
        default: nil,
        index: false,
        foreign_key: { to_table: :packages_packages, on_delete: :cascade }
      t.references :project,
        null: false,
        index: true,
        foreign_key: { on_delete: :nullify },
        type: :bigint
      t.jsonb :fields, null: false

      t.check_constraint "char_length((fields)::text) <= #{10.megabytes}"
    end
  end
end
