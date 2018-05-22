class MergeRequestDiffEntity < Grape::Entity
  include Gitlab::Routing
  include GitHelper
  include MergeRequestsHelper

  expose :version_index do |merge_request_diff|
    @merge_request_diffs = options[:merge_request_diffs]

    version_index(merge_request_diff)
  end

  expose :created_at
  expose :commits_count

  expose :latest?, as: :latest

  expose :short_commit_sha do |merge_request_diff|
    short_sha(merge_request_diff.head_commit_sha)
  end

  expose :version_path do |merge_request_diff|
    merge_request = options[:merge_request]
    start_sha = options[:start_sha]
    project = merge_request.source_project

    merge_request_version_path(project, merge_request, merge_request_diff, start_sha) if project
  end

  expose :compare_path do |merge_request_diff|
    merge_request = options[:merge_request]
    project = merge_request.source_project
    diff = options[:merge_request_diff]

    if project && diff
      merge_request_version_path(project, merge_request, diff, merge_request_diff.head_commit_sha)
    end
  end
end
