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
        title: FFaker::Lorem.sentence(6),
        description: FFaker::Lorem.sentences(3).join(" "),
        milestone: project.milestones.sample,
        assignee: project.team.users.sample
      }

      MergeRequests::CreateService.new(project, project.team.users.sample, params).execute
      print '.'
    end
  end

  project = Project.find_with_namespace('gitlab-org/gitlab-test')

  params = {
    source_branch: 'feature',
    target_branch: 'master',
    title: 'Can be automatically merged'
  }
  MergeRequests::CreateService.new(project, User.admins.first, params).execute
  print '.'

  params = {
    source_branch: 'feature_conflict',
    target_branch: 'feature',
    title: 'Cannot be automatically merged'
  }
  MergeRequests::CreateService.new(project, User.admins.first, params).execute
  print '.'
end
