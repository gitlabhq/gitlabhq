class MigrateProjectTags < ActiveRecord::Migration
  def up
    ActsAsTaggableOn::Tagging.where(taggable_type: 'Project', context: 'labels').update_all(context: 'tags')
  end

  def down
    ActsAsTaggableOn::Tagging.where(taggable_type: 'Project', context: 'tags').update_all(context: 'labels')
  end
end
