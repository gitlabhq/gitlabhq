class MigrateBuildToCommits < ActiveRecord::Migration
  def change
    execute <<eos
INSERT INTO commits ( sha, project_id, ref, before_sha, push_data )
SELECT sha, project_id, ref, before_sha, push_data FROM builds
WHERE id IN (SELECT MAX(id) FROM builds GROUP BY sha)
eos


    if ActiveRecord::Base.connection.adapter_name == 'PostgreSQL'
      execute <<eos
UPDATE builds
SET commit_id = commits.id
FROM commits
WHERE commits.sha = builds.sha
eos
    else
      execute "UPDATE builds b, commits c SET b.commit_id = c.id WHERE c.sha = b.sha"
    end
  end
end
