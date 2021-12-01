# frozen_string_literal: true

class CreateCiProjectMirrors < Gitlab::Database::Migration[1.0]
  TABLE_NAME = :ci_project_mirrors

  def change
    create_table TABLE_NAME do |t|
      t.integer :project_id, null: false, index: { unique: true }
      t.integer :namespace_id, null: false, index: true
    end
  end
end
