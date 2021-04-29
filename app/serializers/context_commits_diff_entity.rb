# frozen_string_literal: true

class ContextCommitsDiffEntity < Grape::Entity
  include Gitlab::Routing

  expose :commits_count

  expose :showing_context_commits_diff do |_, options|
    options[:only_context_commits]
  end

  expose :diffs_path do |diff|
    merge_request = diff.merge_request
    project = merge_request.target_project

    next unless project

    diffs_project_merge_request_path(project, merge_request, only_context_commits: true)
  end
end
