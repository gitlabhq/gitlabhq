module Gitlab
  module ImportExport
    class ProjectTreeRestorer

      def initialize(user:, shared:, namespace_id:)
        @path = File.join(shared.export_path, 'project.json')
        @user = user
        @project_path = shared.opts[:project_path]
        @namespace_id = namespace_id
        @shared = shared
      end

      def restore
        json = IO.read(@path)
        @tree_hash = ActiveSupport::JSON.decode(json)
        @project_members = @tree_hash.delete('project_members')
        create_relations
      rescue => e
        @shared.error(e)
        false
      end

      def project
        @project ||= create_project
      end

      private

      def members_mapper
        @members_mapper ||= Gitlab::ImportExport::MembersMapper.new(exported_members: @project_members,
                                                                    user: @user,
                                                                    project: project)
      end

      # Loops through the tree of models defined in import_export.yml and
      # finds them in the imported JSON so they can be instantiated and saved
      # in the DB. The structure and relationships between models are guessed from
      # the configuration yaml file too.
      # Finally, it updates each attribute in the newly imported project.
      def create_relations
        saved = []
        default_relation_list.each do |relation|
          next unless relation.is_a?(Hash) || @tree_hash[relation.to_s].present?

          create_sub_relations(relation, @tree_hash) if relation.is_a?(Hash)

          relation_key = relation.is_a?(Hash) ? relation.keys.first : relation
          relation_hash = create_relation(relation_key, @tree_hash[relation_key.to_s])
          saved << project.update_attribute(relation_key, relation_hash)
        end
        saved.all?
      end

      def default_relation_list
        Gitlab::ImportExport::ImportExportReader.new(shared: @shared).tree.reject do |model|
          model.is_a?(Hash) && model[:project_members]
        end
      end

      def create_project
        project_params = @tree_hash.reject { |_key, value| value.is_a?(Array) }
        project = Gitlab::ImportExport::ProjectFactory.create(
          project_params: project_params, user: @user, namespace_id: @namespace_id)
        project.path = @project_path
        project.name = @project_path
        project.save!
        project
      end

      def create_sub_relations(relation, tree_hash)
        relation_key = relation.keys.first.to_s
        tree_hash[relation_key].each do |relation_item|
          relation.values.flatten.each do |sub_relation|

            if sub_relation.is_a?(Hash)
              relation_hash = relation_item[sub_relation.keys.first.to_s]
              sub_relation = sub_relation.keys.first
            else
              relation_hash = relation_item[sub_relation.to_s]
            end

            relation_item[sub_relation.to_s] = create_relation(sub_relation, relation_hash) unless relation_hash.blank?
          end
        end
      end

      def create_relation(relation, relation_hash_list)
        relation_array = [relation_hash_list].flatten.map do |relation_hash|
          Gitlab::ImportExport::RelationFactory.create(relation_sym: relation.to_sym,
                                                       relation_hash: relation_hash.merge('project_id' => project.id),
                                                       members_mapper: members_mapper,
                                                       user_admin: @user.is_admin?)
        end

        relation_hash_list.is_a?(Array) ? relation_array : relation_array.first
      end
    end
  end
end
