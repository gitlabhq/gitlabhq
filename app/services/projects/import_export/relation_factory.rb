module Projects
  module ImportExport
    module RelationFactory
      extend self

      OVERRIDES = { snippets: :project_snippets }.freeze
      USER_REFERENCES = %w(author_id assignee_id updated_by_id).freeze

      def create(relation_sym:, relation_hash:, members_map:)
        relation_sym = parse_relation_sym(relation_sym)
        klass = relation_class(relation_sym)
        relation_hash.delete('id') #screw IDs for now
        #TODO refactor this...
        if relation_sym == :merge_requests
          relation_hash['target_project_id'] = relation_hash.delete('project_id')
          relation_hash['source_project_id'] = -1
          relation_hash['importing'] = true
        end
        update_user_references(relation_hash, members_map)
        klass.new(relation_hash)
      end

      private

      #TODO nice to have, optimize this to only get called for specific models
      def update_user_references(relation_hash, members_map)
        USER_REFERENCES.each do |reference|
          if relation_hash[reference]
            relation_hash[reference] = members_map[relation_hash[reference]]
          end
        end
      end

      def relation_class(relation_sym)
        relation_sym.to_s.classify.constantize
      end

      def parse_relation_sym(relation_sym)
        OVERRIDES[relation_sym] || relation_sym
      end
    end
  end
end
