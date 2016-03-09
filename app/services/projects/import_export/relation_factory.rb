module Projects
  module ImportExport
    module RelationFactory
      extend self

      OVERRIDES = { snippets: :project_snippets }

      def create(relation_sym:, relation_hash:)
        relation_sym = parse_relation_sym(relation_sym)
        klass = relation_class(relation_sym)
        relation_hash.delete('id') #screw IDs for now
        klass.new(relation_hash)
      end

      private

      def relation_class(relation_sym)
        relation_sym.to_s.classify.constantize
      end

      def parse_relation_sym(relation_sym)
        OVERRIDES[relation_sym] || relation_sym
      end
    end
  end
end
