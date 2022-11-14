# frozen_string_literal: true

class CreateProjectWikiRepositories < Gitlab::Database::Migration[2.0]
  def change
    create_table :project_wiki_repositories do |t|
      t.references :project, index: { unique: true }, foreign_key: { on_delete: :cascade }, null: false

      t.timestamps_with_timezone null: false
    end
  end
end
