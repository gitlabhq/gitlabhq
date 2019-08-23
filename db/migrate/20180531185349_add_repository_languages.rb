class AddRepositoryLanguages < ActiveRecord::Migration[4.2]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  def up
    # rubocop:disable Migration/AddLimitToStringColumns
    create_table(:programming_languages) do |t|
      t.string :name, null: false
      t.string :color, null: false
      t.datetime_with_timezone :created_at, null: false
    end

    create_table(:repository_languages, id: false) do |t|
      t.references :project, null: false, foreign_key: { on_delete: :cascade }
      t.references :programming_language, null: false
      t.float :share, null: false
    end

    add_index :programming_languages, :name, unique: true
    add_index :repository_languages, [:project_id, :programming_language_id],
      unique: true, name: "index_repository_languages_on_project_and_languages_id"
    # rubocop:enable Migration/AddLimitToStringColumns
  end

  def down
    drop_table :repository_languages
    drop_table :programming_languages
  end
end
