module Projects
  module ImportExport
    class ProjectTreeRestorer
      attr_reader :project

      def initialize(path:, user:)
        @path = path
        @user = user
      end

      #TODO deal with ID issues.
      #TODO refactor this method
      def restore
        json = IO.read(@path)
        tree_hash = ActiveSupport::JSON.decode(json)
        project_params = tree_hash.reject { |_key, value| value.is_a?(Array) }
        project = Projects::ImportExport::ProjectFactory.create(project_params: project_params, user: @user)
        project.save
        relation_hash = {}
        ImportExport.project_tree.each do |relation|
          next if tree_hash[relation.to_s].empty?
          relation_hash[relation.to_s] = create_relation(relation, tree_hash[relation.to_s], project.id)
          project.update_attribute(relation, relation_hash[relation.to_s])
        end
      end

      private

      def create_relation(relation, relation_hash_list, project_id)
        relation_hash_list.map do |relation_hash|
          Projects::ImportExport::RelationFactory.create(
            relation_sym: relation, relation_hash: relation_hash.merge(project_id: project_id))
        end
      end
    end
  end
end
