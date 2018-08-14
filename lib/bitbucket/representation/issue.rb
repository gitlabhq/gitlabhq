module Bitbucket
  module Representation
    class Issue < Representation::Base
      CLOSED_STATUS = %w(resolved invalid duplicate wontfix closed).freeze

      def iid
        raw['id']
      end

      def kind
        raw['kind']
      end

      def author
        raw.dig('reporter', 'username')
      end

      def description
        raw.fetch('content', {}).fetch('raw', nil)
      end

      def state
        closed? ? 'closed' : 'opened'
      end

      def title
        raw['title']
      end

      def milestone
        raw['milestone']['name'] if raw['milestone'].present?
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
    end
  end
end
