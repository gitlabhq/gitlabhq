Gitlab::Seeder.quiet do
  Project.all.each do |project|
    10.times do
      issue_params = {
        title: FFaker::Lorem.sentence(6),
        description: FFaker::Lorem.sentence,
        state: ['opened', 'closed'].sample,
        milestone: project.milestones.sample,
        assignee: project.team.users.sample
      }

      Issues::CreateService.new(project, project.team.users.sample, issue_params).execute
      print '.'
    end
  end
end
