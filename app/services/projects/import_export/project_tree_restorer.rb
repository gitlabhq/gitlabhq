module Projects
  module ImportExport
    class ProjectTreeRestorer
      attr_reader :full_path

      def initialize(path: )
        @path = path
      end

      def restore
        json = IO.read(@path)
        tree_hash = ActiveSupport::JSON.decode(json)
        ImportExport.project_tree.each do |relation|
          next if tree_hash[relation.to_s].empty?
          tree_hash[relation.to_s] = create_relation(relation, tree_hash[relation.to_s])
        end
        project = Project.new(tree_hash)
        project
      end

      private

      def create_relation(relation, tree_hash)
        Projects::ImportExport::RelationFactory.create(
          relation_sym: relation, relation_hash: tree_hash[relation.to_s])
      end

    end
  end
end
