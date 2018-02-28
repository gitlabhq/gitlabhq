module Github
  module Representation
    class Issue < Representation::Issuable
      def state
        raw['state'] == 'closed' ? 'closed' : 'opened'
      end

      def comments?
        raw['comments'] > 0
      end

      def pull_request?
        raw['pull_request'].present?
      end

      def assigned?
        raw['assignees'].present?
      end

      def assignees
        @assignees ||= Array(raw['assignees']).map do |user|
          Github::Representation::User.new(user, options)
        end
      end
    end
  end
end
