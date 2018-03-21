module Banzai
  module ReferenceParser
    class IssuableParser < BaseParser
      def nodes_visible_to_user(user, nodes)
        records = records_for_nodes(nodes)

        nodes.select do |node|
          issuable = records[node]

          issuable && can_read_reference?(user, issuable)
        end
      end

      def referenced_by(nodes)
        records = records_for_nodes(nodes)

        nodes.map { |node| records[node] }.compact.uniq
      end

      def can_read_reference?(user, issuable)
        can?(user, "read_#{issuable.class.to_s.underscore}_iid".to_sym, issuable)
      end
    end
  end
end
