# frozen_string_literal: true

module BitbucketServer
  module Representation
    class PullRequest < Representation::Base
      def author
        raw.dig('author', 'user', 'name')
      end

      def author_email
        raw.dig('author', 'user', 'emailAddress')
      end

      def author_username
        raw.dig('author', 'user', 'username') ||
          raw.dig('author', 'user', 'slug') ||
          raw.dig('author', 'user', 'displayName')
      end

      def description
        raw['description']
      end

      def reviewers
        raw['reviewers']
      end

      def iid
        raw['id']
      end

      def state
        case raw['state']
        when 'MERGED'
          'merged'
        when 'DECLINED'
          'closed'
        else
          'opened'
        end
      end

      def merged?
        state == 'merged'
      end

      def closed?
        state == 'closed'
      end

      def created_at
        self.class.convert_timestamp(created_date)
      end

      def updated_at
        self.class.convert_timestamp(updated_date)
      end

      def title
        raw['title']
      end

      def source_branch_name
        raw.dig('fromRef', 'id')
      end

      def source_branch_sha
        raw.dig('fromRef', 'latestCommit')
      end

      def target_branch_name
        raw.dig('toRef', 'id')
      end

      def target_branch_sha
        raw.dig('toRef', 'latestCommit')
      end

      def to_hash
        {
          iid: iid,
          author: author,
          author_email: author_email,
          author_username: author_username,
          description: description,
          reviewers: reviewers,
          created_at: created_at,
          updated_at: updated_at,
          state: state,
          title: title,
          source_branch_name: source_branch_name,
          source_branch_sha: source_branch_sha,
          target_branch_name: target_branch_name,
          target_branch_sha: target_branch_sha
        }
      end

      private

      def created_date
        raw['createdDate']
      end

      def updated_date
        raw['updatedDate']
      end
    end
  end
end
