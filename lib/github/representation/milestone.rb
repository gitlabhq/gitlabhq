module Github
  module Representation
    class Milestone < Representation::Base
      def iid
        raw['number']
      end

      def title
        raw['title']
      end

      def description
        raw['description']
      end

      def due_date
        raw['due_on']
      end

      def state
        raw['state'] == 'closed' ? 'closed' : 'active'
      end
    end
  end
end
