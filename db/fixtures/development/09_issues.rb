Gitlab::Seeder.quiet do
  Project.all.each do |project|
    (1..10).each  do |i|
      issue_params = {
        title: Faker::Lorem.sentence(6),
        description: Faker::Lorem.sentence,
        state: ['opened', 'closed'].sample,
        milestone: project.milestones.sample,
        assignee: project.team.users.sample
      }

      Issues::CreateService.new(project, project.team.users.sample, issue_params).execute
      print '.'
    end
  end
end
