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
      end

      private

      def members_map
        @members ||= Projects::ImportExport::MembersMapper.map(
          exported_members: @tree_hash.delete('project_members'), user: @user, project_id: project.id)
      end

      def create_relations
        (ImportExport.project_tree - [:project_members]).each do |relation|
          next if @tree_hash[relation.to_s].empty?
          relation_hash = create_relation(relation, @tree_hash[relation.to_s])
          project.update_attribute(relation, relation_hash)
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
        relation_hash_list.map do |relation_hash|
          Projects::ImportExport::RelationFactory.create(
            relation_sym: relation, relation_hash: relation_hash.merge(project_id: project.id), members_map: members_map)
        end
      end
    end
  end
end
