# frozen_string_literal: true

class CreateSecProjectMirrors < Gitlab::Database::Migration[2.3]
  milestone '19.5'

  def change
    create_table :sec_project_mirrors, id: false do |t|
      t.bigint :project_id, primary_key: true, default: nil
      t.bigint :namespace_id, null: false
      t.bigint :organization_id, null: false

      t.index :namespace_id
      t.index [:organization_id, :project_id]
    end
  end
end
