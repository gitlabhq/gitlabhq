module Github
  module Representation
    class Issuable < Representation::Base
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
        @author ||= Github::Representation::User.new(raw['user'], options)
      end

      def assignee
        return unless assigned?

        @assignee ||= Github::Representation::User.new(raw['assignee'], options)
      end

      def assigned?
        raw['assignee'].present?
      end
    end
  end
end
