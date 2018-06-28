module BitbucketServer
  module Representation
    class Activity < Representation::Base
      def action
        raw['action']
      end

      def comment?
        action == 'COMMENTED'.freeze
      end

      def inline_comment?
        comment? && raw['commentAnchor']
      end

      def comment
        return unless comment?

        @comment ||=
          if inline_comment?
            PullRequestComment.new(raw_comment)
          else
            Comment.new(raw_comment)
          end
      end

      # XXX Move this into MergeEvent
      def merge_event?
        action == 'MERGED'
      end

      def committer_user
        commit.fetch('committer', {})['displayName']
      end

      def committer_email
        commit.fetch('committer', {})['emailAddress']
      end

      def merge_timestamp
        timestamp = commit.fetch('committer', {})['commiterTimestamp']

        Time.at(timestamp / 1000.0) if timestamp.is_a?(Integer)
      end

      def commit
        raw.fetch('commit', {})
      end

      def created_at
        Time.at(created_date / 1000) if created_date.is_a?(Integer)
      end

      def updated_at
        Time.at(updated_date / 1000) if created_date.is_a?(Integer)
      end

      private

      def raw_comment
        raw.fetch('comment', {})
      end

      def author
        raw_comment.fetch('author', {})
      end

      # Anchor hash:
      # {u'toHash': u'a4c2164330f2549f67c13f36a93884cf66e976be', u'fromHash': u'c5f4288162e2e6218180779c7f6ac1735bb56eab', u'fileType': u'FROM', u'diffType': u'EFFECTIVE', u'lineType': u'CONTEXT', u'path': u'CHANGELOG.md', u'line': 3, u'orphaned': False}

      def created_date
        comment['createdDate']
      end

      def updated_date
        comment['updatedDate']
      end
    end
  end
end
