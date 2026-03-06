# frozen_string_literal: true

module RapidDiffs
  class DiffVersionEntity < Grape::Entity
    include Gitlab::Routing
    include MergeRequestsHelper
    include Gitlab::Utils::StrongMemoize

    expose :id

    expose :version_index do |merge_request_diff|
      diff_version_index(merge_request_diff)
    end

    expose :merge_head?, as: :head
    expose :latest?, as: :latest

    expose :short_commit_sha do |merge_request_diff|
      next unless merge_request_diff.head_commit_sha

      Commit.truncate_sha(merge_request_diff.head_commit_sha)
    end

    expose :commits_count
    expose :created_at

    protected

    def diff_version_index(merge_request_diff)
      return unless merge_request_diffs.include?(merge_request_diff)
      return unless merge_request_diffs.size > 1

      merge_request_diffs.size - merge_request_diffs.index(merge_request_diff)
    end

    def latest_or_merge_head?(merge_request_diff)
      strong_memoize_with(:latest_or_merge_head, merge_request_diff.id) do
        merge_request_diff.latest? || merge_request_diff.merge_head?
      end
    end

    def merge_request
      options[:merge_request]
    end

    def merge_request_diffs
      options[:merge_request_diffs]
    end

    def current_merge_request_diff
      return if options[:diff_id].blank?

      ::Gitlab::MergeRequests::DiffVersion
        .new(merge_request, diff_id: options[:diff_id])
        .resolve
    end
    strong_memoize_attr :current_merge_request_diff

    def path_options
      { rapid_diffs: true }
    end
  end
end
