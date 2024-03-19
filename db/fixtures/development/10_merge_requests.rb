# frozen_string_literal: true

require './spec/support/sidekiq_middleware'

# Normally merge requests build their diffs in an async
# job via NewMergeRequestWorker, but this method will
# force the after_create actions to happen inline.
def flush_after_commit_queue(merge_request)
  # To prevent idle in transaction timeouts, defer the creation of the
  # NewMergeRequestWorker in a real Sidekiq job.
  Sidekiq::Testing.disable! do
    Gitlab::ExclusiveLease.skipping_transaction_check do
      # Seed-Fu runs this entire fixture in a transaction, so the `after_commit`
      # hook won't run until after the fixture is loaded. That is too late
      # since the Sidekiq::Testing block has already exited. Force clearing
      # the `after_commit` queue to ensure the job is run now.
      merge_request.send(:_run_after_commit_queue)
    end
  end
end

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
      label_ids += project.group.labels.sample(3).pluck(:id) if project.group

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
        merge_request = MergeRequests::CreateService.new(project: project, current_user: developer, params: params).execute
        flush_after_commit_queue(merge_request)
      rescue Repository::AmbiguousRefError
        # Ignore pipelines creation errors for now, we can doing that after
        # https://gitlab.com/gitlab-org/gitlab-foss/issues/55966. will be resolved.
      end
      print '.'
    end
  end

  project = Project.find_by_full_path('gitlab-org/gitlab-test')

  next if !project || project.empty_repo? # We don't have repository on CI

  params = {
    source_branch: 'feature',
    target_branch: 'master',
    title: 'Can be automatically merged'
  }
  Sidekiq::Worker.skipping_transaction_check do
    merge_request = MergeRequests::CreateService.new(project: project, current_user: User.admins.first, params: params).execute
    flush_after_commit_queue(merge_request)
  end
  print '.'

  params = {
    source_branch: 'feature_conflict',
    target_branch: 'feature',
    title: 'Cannot be automatically merged'
  }
  Sidekiq::Worker.skipping_transaction_check do
    merge_request = MergeRequests::CreateService.new(project: project, current_user: User.admins.first, params: params).execute
    flush_after_commit_queue(merge_request)
  end
  print '.'
end
