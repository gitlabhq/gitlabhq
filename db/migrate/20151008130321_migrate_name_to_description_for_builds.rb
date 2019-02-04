# rubocop:disable all
class MigrateNameToDescriptionForBuilds < ActiveRecord::Migration[4.2]
  def change
    execute("UPDATE ci_builds SET type='Ci::Build' WHERE type IS NULL")
  end
end
