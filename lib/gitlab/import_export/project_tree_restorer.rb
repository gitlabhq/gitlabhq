module Gitlab
  module ImportExport
    class ProjectTreeRestorer
      attr_reader :project

      def initialize(path:, user:)
        @path = File.join(path, 'project.json')
        @user = user
      end

      def restore
        json = IO.read(@path)
        @tree_hash = ActiveSupport::JSON.decode(json)
        @project_members = @tree_hash.delete('project_members')
        create_relations
      end

      private

      def members_map
        @members ||= Gitlab::ImportExport::MembersMapper.map(
          exported_members: @project_members, user: @user, project_id: project.id)
      end

      def create_relations(relation_list = default_relation_list, tree_hash = @tree_hash)
        saved = []
        relation_list.each do |relation|
          next if !relation.is_a?(Hash) && tree_hash[relation.to_s].blank?
          if relation.is_a?(Hash)
            create_sub_relations(relation, tree_hash)
          end
          relation_key = relation.is_a?(Hash) ? relation.keys.first : relation
          relation_hash = create_relation(relation_key, tree_hash[relation_key.to_s])
          saved << project.update_attribute(relation_key, relation_hash)
        end
        saved.all?
      end

      def default_relation_list
        Gitlab::ImportExport::ImportExportReader.tree.reject { |model| model.is_a?(Hash) && model[:project_members] }
      end

      def project
        @project ||= create_project
      end

      def create_project
        project_params = @tree_hash.reject { |_key, value| value.is_a?(Array) }
        project = Gitlab::ImportExport::ProjectFactory.create(
          project_params: project_params, user: @user)
        project.save
        project.import_start
        project
      end

      def create_sub_relations(relation, tree_hash)
        tree_hash[relation.keys.first.to_s].each do |relation_item|
          relation.values.flatten.each do |sub_relation|
            relation_hash = relation_item[sub_relation.to_s]
            next if relation_hash.blank?
            process_sub_relation(relation_hash, relation_item, sub_relation)
          end
        end
      end

      def process_sub_relation(relation_hash, relation_item, sub_relation)
        sub_relation_object = nil
        if relation_hash.is_a?(Array)
          sub_relation_object = create_relation(sub_relation, relation_hash)
        else
          sub_relation_object = relation_from_factory(sub_relation, relation_hash)
        end
        relation_item[sub_relation.to_s] = sub_relation_object
      end

      def create_relation(relation, relation_hash_list)
        [relation_hash_list].flatten.map do |relation_hash|
          relation_from_factory(relation, relation_hash)
        end
      end

      def relation_from_factory(relation, relation_hash)
        Gitlab::ImportExport::RelationFactory.create(
          relation_sym: relation, relation_hash: relation_hash.merge('project_id' => project.id), members_map: members_map)
      end
    end
  end
end
