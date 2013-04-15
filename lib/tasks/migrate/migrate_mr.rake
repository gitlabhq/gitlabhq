# This taks will reload commits/diff for all merge requests
desc "GITLAB | Migrate Merge Requests"
task migrate_merge_requests: :environment do
  puts "Since 5.1 old merge request serialization logic was replaced with a better one."
  puts "It makes old merge request diff invalid for GitLab 5.1+"
  puts "* * *"
  puts "This will rebuild commits/diffs info for existing merge requests."
  puts "You will lose merge request diff if its already merged."
  ask_to_continue

  MergeRequest.find_each(batch_size: 20) do |mr|
    mr.st_commits = []
    mr.save
    mr.reload_code
    print '.'
  end
end

