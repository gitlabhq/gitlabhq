# This taks will reload commits/diff for all merge requests
desc "GITLAB | Migrate Merge Requests"
task migrate_merge_requests: :environment do
  MergeRequest.find_each(batch_size: 20) do |mr|
    mr.st_commits = []
    mr.save
    mr.reload_code
    print '.'
  end
end

