module Gitlab
  module ImportExport
    module RelationFactory
      extend self

      OVERRIDES = { snippets: :project_snippets, ci_commits: 'Ci::Commit', statuses: 'commit_status' }.freeze
      USER_REFERENCES = %w(author_id assignee_id updated_by_id).freeze

      def create(relation_sym:, relation_hash:, members_mapper:, user_admin:)
        relation_sym = parse_relation_sym(relation_sym)
        klass = parse_relation(relation_hash, relation_sym)

        update_missing_author(relation_hash, members_mapper, user_admin) if relation_sym == :notes
        update_user_references(relation_hash, members_mapper.map)
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

      def update_missing_author(relation_hash, members_map, user_admin)
        old_author_id = relation_hash['author_id']

        # Users with admin access have access to mapping of users
        if user_admin
          relation_hash['author_id'] = members_map.default_project_member
        else
          relation_hash['author_id'] = members_map.map[old_author_id]
        end

        author = relation_hash.delete('author')

        return unless user_admin && members_map.note_member_list.include?(old_author_id)

        relation_hash['note'] = ('*Blank note*') if relation_hash['note'].blank?
        relation_hash['note'] += (missing_author_note(relation_hash['updated_at'], author['name']))
      end

      def missing_author_note(updated_at, author_name)
        timestamp = updated_at.split('.').first
        "\n\n *By #{author_name} on #{timestamp} (imported from GitLab project)*"
      end

      def update_project_references(relation_hash, klass)
        project_id = relation_hash.delete('project_id')

        if relation_hash['source_project_id'] && relation_hash['target_project_id']
          # If source and target are the same, populate them with the new project ID.
          if relation_hash['target_project_id'] == relation_hash['source_project_id']
            relation_hash['source_project_id'] = project_id
          else
            relation_hash['source_project_id'] = -1
          end
        end
        relation_hash['target_project_id'] = project_id if relation_hash['target_project_id']

        # project_id may not be part of the export, but we always need to populate it if required.
        relation_hash['project_id'] = project_id if klass.column_names.include?('project_id')
        relation_hash['gl_project_id'] = project_id if relation_hash ['gl_project_id']
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
