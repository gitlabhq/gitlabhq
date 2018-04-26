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

  expose :short_commit_sha do |merge_request_diff|
    short_sha(merge_request_diff.head_commit_sha)
  end

  expose :path do |merge_request_diff|
    merge_request = options[:merge_request]
    project = merge_request.source_project

    merge_request_version_path(project, merge_request, merge_request_diff, merge_request_diff.start_commit_sha)
  end
end
