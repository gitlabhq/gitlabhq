# frozen_string_literal: true

class MergeRequestDiffEntity < Grape::Entity
  include Gitlab::Routing
  include GitHelper
  include MergeRequestsHelper

  expose :version_index do |merge_request_diff|
    merge_request_diffs = options[:merge_request_diffs]
    diff = options[:merge_request_diff]

    next unless merge_request_diffs.include?(diff)
    next unless merge_request_diffs.size > 1

    merge_request_diffs.size - merge_request_diffs.index(merge_request_diff)
  end

  expose :created_at
  expose :commits_count

  expose :latest?, as: :latest

  expose :short_commit_sha do |merge_request_diff|
    next unless merge_request_diff.head_commit_sha

    short_sha(merge_request_diff.head_commit_sha)
  end

  expose :base_version_path do |merge_request_diff|
    project = merge_request.target_project

    next unless project

    merge_request_version_path(project, merge_request, merge_request_diff)
  end

  expose :head_version_path do |merge_request_diff|
    project = merge_request.target_project

    next unless project && merge_request.diffable_merge_ref?

    diffs_project_merge_request_path(project, merge_request, diff_head: true)
  end

  expose :version_path do |merge_request_diff|
    start_sha = options[:start_sha]
    project = merge_request.target_project

    next unless project

    merge_request_version_path(project, merge_request, merge_request_diff, start_sha)
  end

  expose :compare_path do |merge_request_diff|
    project = merge_request.target_project
    diff = options[:merge_request_diff]

    if project && diff
      merge_request_version_path(project, merge_request, diff, merge_request_diff.head_commit_sha)
    end
  end

  def merge_request
    options[:merge_request]
  end
end
