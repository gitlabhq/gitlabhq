class RemoveLastVericationFailedColumnsFromProjectRepositoryStates < ActiveRecord::Migration
  DOWNTIME = false

  def up
    remove_column :project_repository_states, :last_repository_verification_failed
    remove_column :project_repository_states, :last_wiki_verification_failed
  end

  def down
    add_column :project_repository_states, :last_repository_verification_failed, :boolean
    add_column :project_repository_states, :last_wiki_verification_failed, :boolean
  end
end
