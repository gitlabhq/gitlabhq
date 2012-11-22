Gitlab::Seeder.quiet do
  (1..300).each  do |i|
    # Random Project
    project_id = rand(2) + 1
    project = Project.find(project_id)

    # Random user
    user = project.users.sample
    user_id = user.id
    MergeRequestObserver.current_user = user

    MergeRequest.seed(:id, [{
      id: i,
      source_branch: 'master',
      target_branch: 'feature',
      project_id: project_id,
      author_id: user_id,
      assignee_id: user_id,
      closed: [true, false].sample,
      milestone: project.milestones.sample,
      title: Faker::Lorem.sentence(6)
    }])
    print('.')
  end
end
