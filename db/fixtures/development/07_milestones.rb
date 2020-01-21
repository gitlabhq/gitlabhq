require './spec/support/sidekiq_middleware'

Gitlab::Seeder.quiet do
  Project.not_mass_generated.each do |project|
    5.times do |i|
      milestone_params = {
        title: "v#{i}.0",
        description: FFaker::Lorem.sentence,
        state: [:active, :closed].sample,
      }

      Milestones::CreateService.new(project, project.team.users.sample, milestone_params).execute

      print '.'
    end
  end
end
