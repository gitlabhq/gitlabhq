# rubocop:disable all
class MigrateRefAndTagToBuild < ActiveRecord::Migration[4.2]
  def change
    execute('UPDATE ci_builds SET ref=(SELECT ref FROM ci_commits WHERE ci_commits.id = ci_builds.commit_id) WHERE ref IS NULL')
    execute('UPDATE ci_builds SET tag=(SELECT tag FROM ci_commits WHERE ci_commits.id = ci_builds.commit_id) WHERE tag IS NULL')
  end
end
