module Projects
  module ImportExport
    class ProjectTreeRestorer
      attr_reader :project

      def initialize(path:, user:)
        @path = path
        @user = user
      end

      def restore
        json = IO.read(@path)
        @tree_hash = ActiveSupport::JSON.decode(json)
        create_relations
        puts project.inspect
      end

      private

      def members_map
        @members ||= Projects::ImportExport::MembersMapper.map(
          exported_members: @tree_hash.delete('project_members'), user: @user, project_id: project.id)
      end

      #TODO Definitely refactor this method!
      #TODO Think about having a yaml file to describe the tree instead of just hashes?
      def create_relations(relation_list = default_relation_list, tree_hash = @tree_hash)
        relation_list.each do |relation|
          relation_hash = nil
          # FIXME
          # next if tree_hash[relation.to_s].blank?
          if (relation.is_a?(Hash) && relation.values.first[:include])
            #TODO name stuff properly
            relation_sym = relation.keys.first
            #TODO remove sub-relation hashes from here so we can save the parent relation first
            relation_hash = create_relation(relation_sym, tree_hash[relation_sym.to_s])
            sub_relations = []
            sub_relation = relation.values.first[:include]
            sub_relation_hash_list = tree_hash[relation.keys.first.to_s]
            sub_relation_hash_list.each do |sub_relation_hash|
              sub_relations << create_relation(relation, sub_relation_hash[relation.to_s])
            end
            relation_hash.update_attribute(sub_relation, sub_relations)
          end
            relation_hash ||= create_relation(relation, tree_hash[relation.to_s])
            project.update_attribute(relation, relation_hash)
        end
      end

      def default_relation_list
        ImportExport.project_tree.reject do |rel|
          rel.is_a?(Hash) && !rel[:project_members].blank?
        end
      end

      def project
        @project ||= create_project
      end

      def create_project
        project_params = @tree_hash.reject { |_key, value| value.is_a?(Array) }
        project = Projects::ImportExport::ProjectFactory.create(
          project_params: project_params, user: @user)
        project.save
        project
      end

      def create_relation(relation, relation_hash_list)
        [relation_hash_list].flatten.map do |relation_hash|
          Projects::ImportExport::RelationFactory.create(
            relation_sym: relation, relation_hash: relation_hash.merge('project_id' => project.id), members_map: members_map)
        end
      end
    end
  end
end
