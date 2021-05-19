# frozen_string_literal: true

class EmptyRepoUploadExperiment < ApplicationExperiment # rubocop:disable Gitlab/NamespacedClass
  include ProjectCommitCount

  TRACKING_START_DATE = DateTime.parse('2021/4/20')
  INITIAL_COMMIT_COUNT = 1

  def track_initial_write
    return unless should_track? # early return if we don't need to ask for commit counts
    return unless context.project.created_at > TRACKING_START_DATE # early return for older projects
    return unless commit_count == INITIAL_COMMIT_COUNT

    track(:initial_write, project: context.project)
  end

  private

  def commit_count
    commit_count_for(context.project, max_count: INITIAL_COMMIT_COUNT, experiment: name)
  end
end
