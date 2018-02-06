class CreateProjectStates < ActiveRecord::Migration
  def change
    create_table :project_states do |t|
      t.references :project, null: false, index: true, foreign_key: true
      t.string :repository_checksum, limit: 64
      t.string :wiki_checksum, limit: 64
      t.datetime_with_timezone :last_repository_check_at
      t.datetime_with_timezone :last_wiki_check_at

      t.timestamps_with_timezone null: false
    end
  end
end
