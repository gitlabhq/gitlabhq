# frozen_string_literal: true

module BitbucketServer
  module Representation
    # An inline comment with the following structure that identifies
    # the part of the diff:
    #
    # "commentAnchor": {
    #   "diffType": "EFFECTIVE",
    #   "fileType": "TO",
    #   "fromHash": "c5f4288162e2e6218180779c7f6ac1735bb56eab",
    #   "line": 1,
    #   "lineType": "ADDED",
    #   "orphaned": false,
    #   "path": "CHANGELOG.md",
    #   "toHash": "a4c2164330f2549f67c13f36a93884cf66e976be"
    #  }
    #
    # More details in https://docs.atlassian.com/bitbucket-server/rest/5.12.0/bitbucket-rest.html.
    class PullRequestComment < Comment
      def from_sha
        comment_anchor['fromHash']
      end

      def to_sha
        comment_anchor['toHash']
      end

      def to?
        file_type == 'TO'
      end

      def from?
        file_type == 'FROM'
      end

      def added?
        line_type == 'ADDED'
      end

      def removed?
        line_type == 'REMOVED'
      end

      # There are three line comment types: added, removed, or context.
      #
      # 1. An added type means a new line was inserted, so there is no old position.
      # 2. A removed type means a line was removed, so there is no new position.
      # 3. A context type means the line was unmodified, so there is both a
      #    old and new position.
      def new_pos
        return if removed?
        return unless line_position

        line_position[1]
      end

      def old_pos
        return if added?
        return unless line_position

        line_position[0]
      end

      def file_path
        comment_anchor.fetch('path')
      end

      def to_hash
        super.merge(
          from_sha: from_sha,
          to_sha: to_sha,
          file_path: file_path,
          old_pos: old_pos,
          new_pos: new_pos
        )
      end

      private

      def file_type
        comment_anchor['fileType']
      end

      def line_type
        comment_anchor['lineType']
      end

      # Each comment contains the following information about the diff:
      #
      # hunks: [
      #     {
      #         segments: [
      #             {
      #                 "lines": [
      #                     {
      #                         "commentIds": [ N ],
      #                         "source": X,
      #                         "destination": Y
      #                     }, ...
      #                   ] ....
      #
      # To determine the line position of a comment, we search all the lines
      # entries until we find this comment ID.
      def line_position
        @line_position ||= diff_hunks.each do |hunk|
          segments = hunk.fetch('segments', [])
          segments.each do |segment|
            lines = segment.fetch('lines', [])
            lines.each do |line|
              if line['commentIds']&.include?(id)
                return [line['source'], line['destination']]
              end
            end
          end
        end
      end

      def comment_anchor
        raw.fetch('commentAnchor', {})
      end

      def diff
        raw.fetch('diff', {})
      end

      def diff_hunks
        diff.fetch('hunks', [])
      end
    end
  end
end
