module Projects
  module ImportExport
    module RelationFactory
      extend self

      def create(relation_sym: , relation_hash:)
        klass = relation_class(relation_sym)
        klass.new(relation_hash)
      end

      private

      def relation_class(relation_sym)
        relation_sym.to_s.classify.constantize
      end
    end
  end
end
