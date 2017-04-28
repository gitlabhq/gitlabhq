module Github
  module Representation
    class Issue < Representation::Issuable
      def labels
        raw['labels']
      end

      def state
        raw['state'] == 'closed' ? 'closed' : 'opened'
      end

      def has_comments?
        raw['comments'] > 0
      end

      def has_labels?
        labels.count > 0
      end

      def pull_request?
        raw['pull_request'].present?
      end
    end
  end
end
