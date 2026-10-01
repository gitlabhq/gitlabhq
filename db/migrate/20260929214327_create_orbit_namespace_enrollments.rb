# frozen_string_literal: true

class CreateOrbitNamespaceEnrollments < Gitlab::Database::Migration[2.3]
  milestone '19.5'

  def change
    create_table :orbit_namespace_enrollments, id: false do |t|
      t.references :namespace, primary_key: true, default: nil, type: :bigint, index: false,
        foreign_key: { to_table: :namespaces, on_delete: :cascade }
      t.timestamps_with_timezone null: false
      t.datetime_with_timezone :trial_ended_at
      t.integer :source, limit: 2, null: false
    end
  end
end
