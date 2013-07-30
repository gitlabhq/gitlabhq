ActiveRecord::Base.observers.disable :all

Gitlab::Seeder.quiet do
  (1..100).each  do |i|
    # Random Project
    project = Project.all.sample

    # Random user
    user = project.users.sample

    next unless user

    next if project.empty_repo?

    branches = project.repository.branch_names.sample(2)

    next if branches.uniq.size < 2

    user_id = user.id
    Thread.current[:current_user] = user

    MergeRequest.seed(:id, [{
      id: i,
      source_branch: branches.first,
      target_branch: branches.last,
      source_project_id: project.id,
      target_project_id: project.id,
      author_id: user_id,
      assignee_id: user_id,
      milestone: project.milestones.sample,
      title: Faker::Lorem.sentence(6)
    }])
    print('.')
  end
end

puts 'Load diffs for Merge Requests (it will take some time)...'
MergeRequest.all.each do |mr|
  mr.reload_code
  print '.'
end
