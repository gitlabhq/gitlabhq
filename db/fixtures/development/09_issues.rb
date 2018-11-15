require './spec/support/sidekiq'

Gitlab::Seeder.quiet do
  Project.all.each do |project|
    10.times do
      issue_params = {
        title: FFaker::Lorem.sentence(6),
        description: FFaker::Lorem.sentence,
        state: ['opened', 'closed'].sample,
        milestone: project.milestones.sample,
        assignees: [project.team.users.sample],
        created_at: rand(12).months.ago
      }

      Issues::CreateService.new(project, project.team.users.sample, issue_params).execute
      print '.'
    end
  end
end
