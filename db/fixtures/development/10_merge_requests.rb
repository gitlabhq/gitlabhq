require './spec/support/sidekiq_middleware'

Gitlab::Seeder.quiet do
  # Limit the number of merge requests per project to avoid long seeds
  MAX_NUM_MERGE_REQUESTS = 10

  projects = Project
    .non_archived
    .with_merge_requests_enabled
    .not_mass_generated
    .reject(&:empty_repo?)

  projects.each do |project|
    branches = project.repository.branch_names.sample(MAX_NUM_MERGE_REQUESTS * 2)

    branches.each do |branch_name|
      break if branches.size < 2
      source_branch = branches.pop
      target_branch = branches.pop

      label_ids = project.labels.pluck(:id).sample(3)
      label_ids += project.group.labels.sample(3) if project.group

      params = {
        source_branch: source_branch,
        target_branch: target_branch,
        title: FFaker::Lorem.sentence(6),
        description: FFaker::Lorem.sentences(3).join(" "),
        milestone: project.milestones.sample,
        assignees: [project.team.users.sample],
        label_ids: label_ids
      }

      # Only create MRs with users that are allowed to create MRs
      developer = project.team.developers.sample
      break unless developer

      Sidekiq::Worker.skipping_transaction_check do
        MergeRequests::CreateService.new(project, developer, params).execute
      rescue Repository::AmbiguousRefError
        # Ignore pipelines creation errors for now, we can doing that after
        # https://gitlab.com/gitlab-org/gitlab-foss/issues/55966. will be resolved.
      end
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
  Sidekiq::Worker.skipping_transaction_check do
    MergeRequests::CreateService.new(project, User.admins.first, params).execute
  end
  print '.'

  params = {
    source_branch: 'feature_conflict',
    target_branch: 'feature',
    title: 'Cannot be automatically merged'
  }
  Sidekiq::Worker.skipping_transaction_check do
    MergeRequests::CreateService.new(project, User.admins.first, params).execute
  end
  print '.'
end
