# frozen_string_literal: true

module BitbucketServer
  module Representation
    class Activity < Representation::Base
      def action
        raw['action']
      end

      def comment?
        action == 'COMMENTED'
      end

      def inline_comment?
        comment? && comment_anchor
      end

      def comment
        return unless comment?

        @comment ||=
          if inline_comment?
            PullRequestComment.new(raw)
          else
            Comment.new(raw)
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

      def comment_anchor
        raw['commentAnchor']
      end

      def author
        raw_comment.fetch('author', {})
      end

      def created_date
        comment['createdDate']
      end

      def updated_date
        comment['updatedDate']
      end
    end
  end
end
