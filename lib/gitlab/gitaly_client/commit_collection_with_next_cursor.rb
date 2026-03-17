# frozen_string_literal: true

module Gitlab
  module GitalyClient
    class CommitCollectionWithNextCursor < SimpleDelegator
      def initialize(response, repository)
        commits = response.flat_map do |message|
          cursor = message.pagination_cursor&.next_cursor
          @next_cursor = cursor if cursor.present?

          message.commits.map do |gitaly_commit|
            Gitlab::Git::Commit.new(repository, gitaly_commit)
          end
        end

        super(commits)
      end

      attr_reader :next_cursor
    end
  end
end
