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
    class PullRequestComment < Comment
      def file_type
        comment_anchor['fileType']
      end

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

      def new_pos
        return unless to?

        comment_anchor['line']
      end

      def old_pos
        return unless from?

        comment_anchor['line']
      end

      def file_path
        comment_anchor.fetch('path')
      end

      private

      def comment_anchor
        raw.fetch('commentAnchor', {})
      end
    end
  end
end
