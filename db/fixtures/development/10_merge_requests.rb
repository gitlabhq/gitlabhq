Gitlab::Seeder.quiet do
  Project.all.reject(&:empty_repo?).each do |project|
    branches = project.repository.branch_names

    branches.each do |branch_name|
      break if branches.size < 2
      source_branch = branches.pop
      target_branch = branches.pop

      # Random user
      user = project.team.users.sample
      next unless user

      params = {
        source_branch: source_branch,
        target_branch: target_branch,
        title: Faker::Lorem.sentence(6),
        description: Faker::Lorem.sentences(3).join(" ")
      }

      merge_request = MergeRequests::CreateService.new(project, user, params).execute

      if merge_request.valid?
        merge_request.assignee = user
        merge_request.milestone = project.milestones.sample
        merge_request.save
        print '.'
      else
        print 'F'
      end
    end
  end
end
