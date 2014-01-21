ActiveRecord::Base.observers.disable :all

Gitlab::Seeder.quiet do
  (1..300).each  do |i|
    # Random Project
    project = Project.all.sample

    # Random user
    user = project.team.users.sample

    next unless user

    user_id = user.id

    begin
      Thread.current[:current_user] = user

      Issue.seed(:id, [{
        id: i,
        project_id: project.id,
        author_id: user_id,
        assignee_id: user_id,
        state: ['opened', 'closed'].sample,
        milestone: project.milestones.sample,
        title: Faker::Lorem.sentence(6),
        description: Faker::Lorem.sentence
      }])
    ensure
      Thread.current[:current_user] = nil
    end
    print('.')
  end

  Issue.all.map do |issue|
    issue.set_iid
    issue.save
  end
end
