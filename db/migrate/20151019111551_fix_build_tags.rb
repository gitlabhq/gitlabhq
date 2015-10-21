class FixBuildTags < ActiveRecord::Migration
  def change
    execute("UPDATE taggings SET taggable_type='CommitStatus' WHERE taggable_type='Ci::Build'")
  end
end
