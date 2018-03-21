class RemoveLastVerificationAtColumnsFromGeoProjectRegistry < ActiveRecord::Migration
  DOWNTIME = false

  def up
    remove_column :project_registry, :last_repository_verification_at
    remove_column :project_registry, :last_wiki_verification_at
  end

  def down
    add_column :project_registry, :last_repository_verification_at, :datetime_with_timezone
    add_column :project_registry, :last_wiki_verification_at, :datetime_with_timezone
  end
end
