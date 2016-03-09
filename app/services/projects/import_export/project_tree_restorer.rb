module Projects
  module ImportExport
    class ProjectTreeRestorer
      attr_reader :project

      def initialize(path: , user: user)
        @path = path
        @user = user
      end

      #TODO deal with ID issues.
      #TODO refactor this method
      def restore
        json = IO.read(@path)
        tree_hash = ActiveSupport::JSON.decode(json)
        relation_hash = {}
        ImportExport.project_tree.each do |relation|
          next if tree_hash[relation.to_s].empty?
          relation_hash[relation.to_s] = create_relation(relation, tree_hash[relation.to_s])
        end
        project_params = tree_hash.delete_if { |_key, value | value.is_a?(Array)}
        @project = ::Projects::CreateService.new(@user, project_params).execute
        @project.saved?
      end

      private

      def create_relation(relation, relation_hash_list)
        relation_hash_list.map do |relation_hash|
          Projects::ImportExport::RelationFactory.create(
            relation_sym: relation, relation_hash: relation_hash)
        end
      end
    end
  end
end
