Gitlab::Seeder.quiet do
  Project.all.each do |project|
    (1..5).each  do |i|
      milestone_params = {
        title: "v#{i}.0",
        description: Faker::Lorem.sentence,
        state: ['opened', 'closed'].sample,
      }

      milestone = Milestones::CreateService.new(
        project, project.team.users.sample, milestone_params).execute

      print '.'
    end
  end
end
