module Bitbucket
  module Representation
    class Issue < Representation::Base
      CLOSED_STATUS = %w(resolved invalid duplicate wontfix closed).freeze

      def iid
        raw['id']
      end

      def author
        reporter.fetch('username', 'Anonymous')
      end

      def description
        raw.dig('content', 'raw')
      end

      def state
        closed? ? 'closed' : 'opened'
      end

      def title
        raw['title']
      end

      def created_at
        raw['created_on']
      end

      def updated_at
        raw['edited_on']
      end

      def to_s
        iid
      end

      private

      def closed?
        CLOSED_STATUS.include?(raw['state'])
      end

      def reporter
        raw.fetch('reporter', {})
      end
    end
  end
end
