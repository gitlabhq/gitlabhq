module BitbucketServer
  module Representation
    class PullRequest < Representation::Base
      def author
        raw.fetch('author', {}).fetch('user', {}).fetch('name')
      end

      def author_email
        raw.fetch('author', {}).fetch('user', {}).fetch('emailAddress')
      end

      def description
        raw['description']
      end

      def iid
        raw['id']
      end

      def state
        if raw['state'] == 'MERGED'
          'merged'
        elsif raw['state'] == 'DECLINED'
          'closed'
        else
          'opened'
        end
      end

      def merged?
        state == 'merged'
      end

      def created_at
        raw['createdDate']
      end

      def updated_at
        raw['updatedDate']
      end

      def title
        raw['title']
      end

      def source_branch_name
        source_branch['id']
      end

      def source_branch_sha
        source_branch['latestCommit']
      end

      def target_branch_name
        target_branch['id']
      end

      def target_branch_sha
        target_branch['latestCommit']
      end

      private

      def source_branch
        raw['fromRef'] || {}
      end

      def target_branch
        raw['toRef'] || {}
      end
    end
  end
end
