# frozen_string_literal: true

module BitbucketServer
  module Representation
    class Activity < Representation::Base
      def id
        raw['id']
      end

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
        commit.dig('committer', 'displayName')
      end

      def committer_name
        commit.dig('committer', 'displayName')
      end

      def committer_username
        commit.dig('committer', 'slug')
      end

      def committer_email
        commit.dig('committer', 'emailAddress')
      end

      def merge_timestamp
        timestamp = commit['committerTimestamp']

        self.class.convert_timestamp(timestamp)
      end

      def merge_commit
        commit['id']
      end

      def approved_event?
        action == 'APPROVED'
      end

      def approver_name
        raw.dig('user', 'displayName')
      end

      def approver_username
        raw.dig('user', 'slug')
      end

      def approver_email
        raw.dig('user', 'emailAddress')
      end

      def declined_event?
        action == 'DECLINED'
      end

      def decliner_name
        raw.dig('user', 'displayName')
      end

      def decliner_username
        raw.dig('user', 'slug')
      end

      def decliner_email
        raw.dig('user', 'emailAddress')
      end

      def created_at
        self.class.convert_timestamp(created_date)
      end

      def to_hash
        {
          id: id,
          committer_name: committer_user,
          committer_user: committer_user,
          committer_username: committer_username,
          committer_email: committer_email,
          merge_timestamp: merge_timestamp,
          merge_commit: merge_commit,
          approver_name: approver_name,
          approver_username: approver_username,
          approver_email: approver_email,
          decliner_name: decliner_name,
          decliner_username: decliner_username,
          decliner_email: decliner_email,
          created_at: created_at
        }
      end

      private

      def commit
        raw.fetch('commit', {})
      end

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
