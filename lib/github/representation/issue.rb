module Github
  module Representation
    class Issue < Representation::Base
      def iid
        raw['number']
      end

      def title
        raw['title']
      end

      def description
        raw['body'] || ''
      end

      def milestone
        return unless raw['milestone'].present?

        @milestone ||= Github::Representation::Milestone.new(raw['milestone'])
      end

      def author
        @author ||= Github::Representation::User.new(raw['user'])
      end

      def assignee
        return unless assigned?

        @assignee ||= Github::Representation::User.new(raw['assignee'])
      end

      def state
        raw['state'] == 'closed' ? 'closed' : 'opened'
      end

      def url
        raw['url']
      end

      def created_at
        raw['created_at']
      end

      def updated_at
        raw['updated_at']
      end

      def assigned?
        raw['assignee'].present?
      end

      def pull_request?
        raw['pull_request'].present?
      end
    end
  end
end
