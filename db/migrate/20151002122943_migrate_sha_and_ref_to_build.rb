class MigrateShaAndRefToBuild < ActiveRecord::Migration
  def change
    execute('UPDATE ci_builds SET ref=(SELECT ref FROM ci_commits WHERE ci_commits.id = ci_builds.commit_id) WHERE ref IS NULL')
    execute('UPDATE ci_builds SET push_data=(SELECT push_data FROM ci_commits WHERE ci_commits.id = ci_builds.commit_id) WHERE push_data IS NULL')
    execute('UPDATE ci_builds SET tag=(SELECT tag FROM ci_commits WHERE ci_commits.id = ci_builds.commit_id) WHERE tag IS NULL')
  end
end
