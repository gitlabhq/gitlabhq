# frozen_string_literal: true

module Bitbucket
  module Representation
    class PullRequest < Representation::Base
      def author
        raw.dig('author', 'uuid')
      end

      def author_nickname
        raw.dig('author', 'nickname')
      end

      def description
        raw['description']
      end

      def iid
        raw['id']
      end

      def state
        case raw['state']
        when 'MERGED'
          'merged'
        when 'DECLINED', 'SUPERSEDED'
          'closed'
        else
          'opened'
        end
      end

      def created_at
        raw['created_on']
      end

      def updated_at
        raw['updated_on']
      end

      def title
        raw['title']
      end

      def source_branch_name
        source_branch&.dig('branch', 'name')
      end

      def source_branch_sha
        source_branch&.dig('commit', 'hash')
      end

      def target_branch_name
        target_branch&.dig('branch', 'name')
      end

      def target_branch_sha
        target_branch&.dig('commit', 'hash')
      end

      def reviewers
        raw['reviewers']&.pluck('uuid')
      end

      def merge_commit_sha
        raw['merge_commit']&.dig('hash')
      end

      def to_hash
        {
          iid: iid,
          author: author,
          author_nickname: author_nickname,
          description: description,
          created_at: created_at,
          updated_at: updated_at,
          state: state,
          title: title,
          source_branch_name: source_branch_name,
          source_branch_sha: source_branch_sha,
          merge_commit_sha: merge_commit_sha,
          target_branch_name: target_branch_name,
          target_branch_sha: target_branch_sha,
          source_and_target_project_different: source_and_target_project_different,
          reviewers: reviewers,
          closed_by: closed_by
        }
      end

      private

      def source_branch
        raw['source']
      end

      def target_branch
        raw['destination']
      end

      def source_repo_uuid
        source_branch&.dig('repository', 'uuid')
      end

      def target_repo_uuid
        target_branch&.dig('repository', 'uuid')
      end

      def source_and_target_project_different
        source_repo_uuid != target_repo_uuid
      end

      def closed_by
        raw['closed_by']&.dig('uuid')
      end
    end
  end
end
