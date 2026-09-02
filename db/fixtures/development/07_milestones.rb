require './spec/support/sidekiq_middleware'

Gitlab::Seeder.quiet do
  Project.not_mass_generated.each do |project|
    # project.team.users reads project_authorizations, which is refreshed asynchronously, so a
    # project can have members but no authorized users yet. CreateService needs an author.
    users = project.team.users.to_a
    next if users.empty?

    5.times do |i|
      milestone_params = {
        title: "v#{i}.0",
        description: FFaker::Lorem.sentence,
        state: [:active, :closed].sample,
      }

      Milestones::CreateService.new(project, users.sample, milestone_params).execute

      print '.'
    end
  end
end
