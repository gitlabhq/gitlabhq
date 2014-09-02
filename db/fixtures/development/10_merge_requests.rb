Gitlab::Seeder.quiet do
  Project.all.reject(&:empty_repo?).each do |project|
    branches = project.repository.branch_names

    branches.each do |branch_name|
      break if branches.size < 2
      source_branch = branches.pop
      target_branch = branches.pop

      params = {
        source_branch: source_branch,
        target_branch: target_branch,
        title: Faker::Lorem.sentence(6),
        description: Faker::Lorem.sentences(3).join(" "),
        milestone: project.milestones.sample,
        assignee: project.team.users.sample
      }

      MergeRequests::CreateService.new(project, project.team.users.sample, params).execute
      print '.'
    end
  end
end
