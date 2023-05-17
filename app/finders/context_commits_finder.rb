# frozen_string_literal: true

class ContextCommitsFinder
  def initialize(project, merge_request, params = {})
    @project = project
    @merge_request = merge_request
    @search = params[:search]
    @author = params[:author]
    @committed_before = params[:committed_before]
    @committed_after = params[:committed_after]
    @limit = (params[:limit] || 40).to_i
  end

  def execute
    commits = init_collection
    filter_existing_commits(commits)
  end

  private

  attr_reader :project, :merge_request, :search, :author, :committed_before, :committed_after, :limit

  def init_collection
    if search_params_present?
      search_commits
    else
      project.repository.commits(merge_request.target_branch, { limit: limit })
    end
  end

  def search_params_present?
    [search, author, committed_before, committed_after].map(&:present?).any?
  end

  def filter_existing_commits(commits)
    commits.select! { |commit| already_included_ids.exclude?(commit.id) }
    commits
  end

  def search_commits
    key = search&.strip
    commits = []
    if Commit.valid_hash?(key)
      mr_existing_commits_ids = merge_request.commits.map(&:id)
      if mr_existing_commits_ids.exclude? key
        commit_by_sha = project.repository.commit(key)
        commits = [commit_by_sha] if commit_by_sha
      end
    else
      commits = project.repository.list_commits_by(search, merge_request.target_branch,
        author: author, before: committed_before, after: committed_after, limit: limit)
    end

    commits
  end

  def already_included_ids
    mr_existing_commits_ids = merge_request.commits.map(&:id)
    mr_context_commits_ids = merge_request.context_commits.map(&:id)

    mr_existing_commits_ids + mr_context_commits_ids
  end
end
