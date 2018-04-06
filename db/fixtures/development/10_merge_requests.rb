require './spec/support/sidekiq'

Gitlab::Seeder.quiet do
  # Limit the number of merge requests per project to avoid long seeds
  MAX_NUM_MERGE_REQUESTS = 10

  Project.non_archived.with_merge_requests_enabled.reject(&:empty_repo?).each do |project|
    branches = project.repository.branch_names.sample(MAX_NUM_MERGE_REQUESTS * 2)

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

      # Only create MRs with users that are allowed to create MRs
      developer = project.team.developers.sample
      break unless developer

      MergeRequests::CreateService.new(project, developer, params).execute
      print '.'
    end
  end

  project = Project.find_by_full_path('gitlab-org/gitlab-test')

  next if project.empty_repo? # We don't have repository on CI

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
