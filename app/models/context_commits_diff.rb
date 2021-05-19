# frozen_string_literal: true

class ContextCommitsDiff
  include ActsAsPaginatedDiff

  attr_reader :merge_request

  def initialize(merge_request)
    @merge_request = merge_request
  end

  def empty?
    commits.empty?
  end

  def commits_count
    merge_request.context_commits_count
  end

  def diffs(diff_options = nil)
    Gitlab::Diff::FileCollection::Compare.new(
      self,
      project: merge_request.project,
      diff_options: diff_options,
      diff_refs: diff_refs
    )
  end

  def raw_diffs(options = {})
    compare.diffs(options.merge(paths: paths))
  end

  def diff_refs
    Gitlab::Diff::DiffRefs.new(
      base_sha: commits.last&.diff_refs&.base_sha,
      head_sha: commits.first&.diff_refs&.head_sha
    )
  end

  private

  def compare
    @compare ||=
      Gitlab::Git::Compare.new(
        merge_request.project.repository.raw_repository,
        commits.last&.diff_refs&.base_sha,
        commits.first&.diff_refs&.head_sha
      )
  end

  def commits
    @commits ||= merge_request.project.repository.commits_by(oids: merge_request.recent_context_commits.map(&:id))
  end

  def paths
    merge_request.merge_request_context_commit_diff_files.map(&:path)
  end
end
