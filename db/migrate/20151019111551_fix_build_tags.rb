class FixBuildTags < ActiveRecord::Migration
  def up
    execute("UPDATE taggings SET taggable_type='CommitStatus' WHERE taggable_type='Ci::Build'")
  end

  def down
    execute("UPDATE taggings SET taggable_type='Ci::Build' WHERE taggable_type='CommitStatus'")
  end
end
