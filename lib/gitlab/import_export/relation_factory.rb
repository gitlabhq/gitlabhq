module Gitlab
  module ImportExport
    module RelationFactory
      extend self

      OVERRIDES = { snippets: :project_snippets, ci_commits: 'Ci::Commit', statuses: 'commit_status' }.freeze
      USER_REFERENCES = %w(author_id assignee_id updated_by_id).freeze

      def create(relation_sym:, relation_hash:, members_map:)
        relation_sym = parse_relation_sym(relation_sym)
        klass = parse_relation(relation_hash, relation_sym)

        update_user_references(relation_hash, members_map)
        update_project_references(relation_hash, klass)

        imported_object(klass, relation_hash)
      end

      private

      def update_user_references(relation_hash, members_map)
        USER_REFERENCES.each do |reference|
          if relation_hash[reference]
            relation_hash[reference] = members_map[relation_hash[reference]]
          end
        end
      end

      def update_project_references(relation_hash, klass)
        project_id = relation_hash.delete('project_id')

        # project_id may not be part of the export, but we always need to populate it if required.
        relation_hash['project_id'] = project_id if klass.column_names.include?('project_id')
        relation_hash['gl_project_id'] = project_id if relation_hash ['gl_project_id']
        relation_hash['target_project_id'] = project_id if relation_hash['target_project_id']
        relation_hash['source_project_id'] = -1 if relation_hash['source_project_id']
      end

      def relation_class(relation_sym)
        relation_sym.to_s.classify.constantize
      end

      def parse_relation_sym(relation_sym)
        OVERRIDES[relation_sym] || relation_sym
      end

      def imported_object(klass, relation_hash)
        imported_object = klass.new(relation_hash)
        imported_object.importing = true if imported_object.respond_to?(:importing)
        imported_object
      end

      def parse_relation(relation_hash, relation_sym)
        klass = relation_class(relation_sym)
        relation_hash.delete('id')
        klass
      end
    end
  end
end
