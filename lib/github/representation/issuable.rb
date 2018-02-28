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

      def labels?
        raw['labels'].any?
      end

      def labels
        @labels ||= Array(raw['labels']).map do |label|
          Github::Representation::Label.new(label, options)
        end
      end
    end
  end
end
