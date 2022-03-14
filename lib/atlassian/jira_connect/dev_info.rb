# frozen_string_literal: true

module Atlassian
  module JiraConnect
    class DevInfo
      URL = '/rest/devinfo/0.10/bulk'

      def initialize(project:, commits: nil, branches: nil, merge_requests: nil, update_sequence_id: nil)
        @project = project
        @commits = commits
        @branches = branches
        @merge_requests = merge_requests
        @update_sequence_id = update_sequence_id
      end

      def url
        URL
      end

      def body
        repo = ::Atlassian::JiraConnect::Serializers::RepositoryEntity.represent(
          @project,
          commits: @commits,
          branches: @branches,
          merge_requests: @merge_requests,
          user_notes_count: user_notes_count,
          update_sequence_id: @update_sequence_id
        )

        { repositories: [repo] }
      end

      def present?
        [@commits, @branches, @merge_requests].any?(&:present?)
      end

      private

      def user_notes_count
        return unless @merge_requests

        Note.count_for_collection(@merge_requests.map(&:id), 'MergeRequest').to_h do |count_group|
          [count_group.noteable_id, count_group.count]
        end
      end
    end
  end
end
