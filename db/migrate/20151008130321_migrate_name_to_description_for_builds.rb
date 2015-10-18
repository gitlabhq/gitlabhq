class MigrateNameToDescriptionForBuilds < ActiveRecord::Migration
  def change
    execute("UPDATE ci_builds SET type='Ci::Build' WHERE type IS NULL")
  end
end
