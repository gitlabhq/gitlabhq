# frozen_string_literal: true

module BitbucketServer
  module Representation
    class Activity < Representation::Base
      def comment?
        action == 'COMMENTED'
      end

      def inline_comment?
        !!(comment? && comment_anchor)
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

      # TODO Move this into MergeEvent
      def merge_event?
        action == 'MERGED'
      end

      def committer_user
        raw.dig('commit', 'committer', 'displayName')
      end

      def committer_email
        raw.dig('commit', 'committer', 'emailAddress')
      end

      def merge_timestamp
        timestamp = raw.dig('commit', 'committerTimestamp')

        Time.at(timestamp / 1000.0) if timestamp.is_a?(Integer)
      end

      def created_at
        Time.at(created_date / 1000) if created_date.is_a?(Integer)
      end

      private

      def action
        raw['action']
      end

      def comment_anchor
        raw['commentAnchor']
      end

      def created_date
        raw['createdDate']
      end
    end
  end
end
