module Banzai
  class ReferenceQuerying
    def self.document_nodes(documents, types = [])
      documents.map { |document| DocumentNodes.new(document, types) }
    end

    class DocumentNodes
      def initialize(document, types = [])
        @document = document
        @types    = types
      end

      attr_reader :document, :types

      def nodes
        types.empty? ? raw_nodes : nodes_by_type.values.flatten
      end

      def nodes_by_type
        @nodes_by_type ||= begin
          per_type = Hash.new { |hash, key| hash[key] = [] }
          raw_nodes.group_by { |node| node.attr('data-reference-type') }.each do |type, nodes|
            type_sym = type.to_sym
            per_type[type_sym] = nodes if types.include?(type_sym)
          end
          per_type
        end
      end

      private

      def raw_nodes
        @raw_nodes ||= Querying.css(document, 'a.gfm[data-reference-type]')
      end
    end
  end
end
