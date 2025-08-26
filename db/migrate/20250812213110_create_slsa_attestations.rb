# frozen_string_literal: true

class CreateSlsaAttestations < Gitlab::Database::Migration[2.3]
  milestone '18.4'

  INDEX_NAME = 'index_slsa_attestations_on_digest_project_predicate_uniq'

  def up
    opts = {
      if_not_exists: true
    }

    create_table :slsa_attestations, **opts do |t|
      t.timestamps_with_timezone null: false
      t.references :project, null: false, index: true, foreign_key: { on_delete: :cascade }
      t.bigint :build_id, index: true
      t.integer :status, null: false, default: 0, limit: 2
      t.datetime_with_timezone :expire_at
      t.integer :predicate_kind, null: false, default: 0, limit: 2
      t.text :predicate_type, null: false, limit: 255
      t.text :subject_digest, null: false, limit: 255
    end

    add_index :slsa_attestations, [:subject_digest, :project_id, :predicate_kind],
      unique: true,
      name: INDEX_NAME
  end

  def down
    drop_table :slsa_attestations
  end
end
