# frozen_string_literal: true

module Bitbucket
  module Representation
    class PullRequest < Representation::Base
      def author
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
        source_branch.dig('branch', 'name')
      end

      def source_branch_sha
        source_branch.dig('commit', 'hash')
      end

      def target_branch_name
        target_branch.dig('branch', 'name')
      end

      def target_branch_sha
        target_branch.dig('commit', 'hash')
      end

      private

      def source_branch
        raw['source']
      end

      def target_branch
        raw['destination']
      end
    end
  end
end
