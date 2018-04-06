  class CreateProjectRepositoryStates < ActiveRecord::Migration
  DOWNTIME = false

  def change
    create_table :project_repository_states do |t|
      t.references :project, null: false, index: { unique: true }, foreign_key: { on_delete: :cascade }
      t.binary :repository_verification_checksum
      t.binary :wiki_verification_checksum
      t.boolean :last_repository_verification_failed, null: false, default: false
      t.boolean :last_wiki_verification_failed, null: false, default: false
      t.datetime_with_timezone :last_repository_verification_at
      t.datetime_with_timezone :last_wiki_verification_at
      t.string :last_repository_verification_failure
      t.string :last_wiki_verification_failure
    end
  end
end
