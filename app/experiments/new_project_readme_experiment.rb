# frozen_string_literal: true

class NewProjectReadmeExperiment < ApplicationExperiment # rubocop:disable Gitlab/NamespacedClass
  include Gitlab::Git::WrapsGitalyErrors

  INITIAL_WRITE_LIMIT = 3
  EXPERIMENT_START_DATE = DateTime.parse('2021/1/20')
  MAX_ACCOUNT_AGE = 7.days

  exclude { context.value[:actor].nil? }
  exclude { context.actor.created_at < MAX_ACCOUNT_AGE.ago }

  def control_behavior
    false # we don't want the checkbox to be checked
  end

  def candidate_behavior
    true # check the checkbox by default
  end

  def track_initial_writes(project)
    return unless should_track? # early return if we don't need to ask for commit counts
    return unless project.created_at > EXPERIMENT_START_DATE # early return for older projects
    return unless (commit_count = commit_count_for(project)) < INITIAL_WRITE_LIMIT

    track(:write, property: project.created_at.to_s, value: commit_count)
  end

  private

  def commit_count_for(project)
    raw_repo = project.repository&.raw_repository
    return INITIAL_WRITE_LIMIT unless raw_repo&.root_ref

    begin
      Gitlab::GitalyClient::CommitService.new(raw_repo).commit_count(raw_repo.root_ref, {
        all: true, # include all branches
        max_count: INITIAL_WRITE_LIMIT # limit as an optimization
      })
    rescue StandardError => e
      Gitlab::ErrorTracking.track_exception(e, experiment: name)
      INITIAL_WRITE_LIMIT
    end
  end
end
