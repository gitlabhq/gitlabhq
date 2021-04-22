# frozen_string_literal: true

class NewProjectReadmeExperiment < ApplicationExperiment # rubocop:disable Gitlab/NamespacedClass
  include ProjectCommitCount

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
    return unless (count = commit_count(project)) < INITIAL_WRITE_LIMIT

    track(:write, property: project.created_at.to_s, value: count)
  end

  private

  def commit_count(project)
    commit_count_for(project,
      default_count: INITIAL_WRITE_LIMIT,
      max_count: INITIAL_WRITE_LIMIT,
      experiment: name
    )
  end
end
