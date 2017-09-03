module Gitlab
  module ImportExport
    class ProjectTreeRestorer
      # Relations which cannot have both group_id and project_id at the same time
      RESTRICT_PROJECT_AND_GROUP = %i(milestones).freeze

      def initialize(user:, shared:, project:)
        @path = File.join(shared.export_path, 'project.json')
        @user = user
        @shared = shared
        @project = project
        @project_id = project.id
      end

      def restore
        begin
          json = IO.read(@path)
          @tree_hash = ActiveSupport::JSON.decode(json)
        rescue => e
          Rails.logger.error("Import/Export error: #{e.message}")
          raise Gitlab::ImportExport::Error.new('Incorrect JSON format')
        end

        @project_members = @tree_hash.delete('project_members')

          ActiveRecord::Base.uncached do
            ActiveRecord::Base.no_touching do
            create_relations
          end
        end
      rescue => e
        @shared.error(e)
        false
      end

      def restored_project
        @restored_project ||= restore_project
      end

      private

      def members_mapper
        @members_mapper ||= Gitlab::ImportExport::MembersMapper.new(exported_members: @project_members,
                                                                    user: @user,
                                                                    project: restored_project)
      end

      # Loops through the tree of models defined in import_export.yml and
      # finds them in the imported JSON so they can be instantiated and saved
      # in the DB. The structure and relationships between models are guessed from
      # the configuration yaml file too.
      # Finally, it updates each attribute in the newly imported project.
      def create_relations
        @saved = []
        default_relation_list.each do |relation|
          next unless relation.is_a?(Hash) || @tree_hash[relation.to_s].present?

          if relation.is_a?(Hash)
            create_sub_relations(relation, @tree_hash)
          else
            relation_key = relation.is_a?(Hash) ? relation.keys.first : relation
            relation_hash_list = @tree_hash[relation_key.to_s]
            save_relation_hash(relation_hash_list, relation_key)
          end


          # relation_key = relation.is_a?(Hash) ? relation.keys.first : relation
          # relation_hash_list = @tree_hash[relation_key.to_s]
          #
          # next unless relation_hash_list
          #
          # if relation_hash_list.is_a?(Array)
          #   [relation_hash_list].flatten.each_slice(15) do |relation_hash_batch|
          #     save_relation_hash(relation_hash_batch, relation_key, saved)
          #   end
          # else
          #   save_relation_hash(relation_hash_list, relation_key, saved)
          # end

        end
        @saved.all?
      end

      def save_relation_hash(relation_hash_batch, relation_key)
        relation_hash = create_relation(relation_key, relation_hash_batch)

        @saved << restored_project.append_or_update_attribute(relation_key, relation_hash)
        @restored_project = Project.find_by_id(@project_id)
      end

      def default_relation_list
        Gitlab::ImportExport::Reader.new(shared: @shared).tree.reject do |model|
          model.is_a?(Hash) && model[:project_members]
        end
      end

      def restore_project
        return @project unless @tree_hash

        @project.update_columns(project_params)
        @project
      end

      def project_params
        @tree_hash.reject do |key, value|
          # return params that are not 1 to many or 1 to 1 relations
          value.respond_to?(:each) && !Project.column_names.include?(key)
        end
      end

      # Given a relation hash containing one or more models and its relationships,
      # loops through each model and each object from a model type and
      # and assigns its correspondent attributes hash from +tree_hash+
      # Example:
      # +relation_key+ issues, loops through the list of *issues* and for each individual
      # issue, finds any subrelations such as notes, creates them and assign them back to the hash
      #
      # Recursively calls this method if the sub-relation is a hash containing more sub-relations
      def create_sub_relations(relation, tree_hash, save = true)
        relation_key = relation.keys.first.to_s
        return if tree_hash[relation_key].blank?

        tree_array = [tree_hash[relation_key]].flatten

        while relation_item = tree_array.shift
            process_sub_relation(relation, relation_item)

            if save
              save_relation_hash([relation_item], relation_key)
              tree_hash[relation_key].delete(relation_item)
            end
        end

        tree_hash.delete(relation_key) if save
      end

      def process_sub_relation(relation, relation_item)
        relation.values.flatten.each do |sub_relation|
          # We just use author to get the user ID, do not attempt to create an instance.
          next if sub_relation == :author

          create_sub_relations(sub_relation, relation_item, false) if sub_relation.is_a?(Hash)

          relation_hash, sub_relation = assign_relation_hash(relation_item, sub_relation)
          relation_item[sub_relation.to_s] = create_relation(sub_relation, relation_hash) unless relation_hash.blank?
        end
      end

      def assign_relation_hash(relation_item, sub_relation)
        if sub_relation.is_a?(Hash)
          relation_hash = relation_item[sub_relation.keys.first.to_s]
          sub_relation = sub_relation.keys.first
        else
          relation_hash = relation_item[sub_relation.to_s]
        end
        [relation_hash, sub_relation]
      end

      def create_relation(relation, relation_hash_list)
        relation_type = relation.to_sym

        relation_array = [relation_hash_list].flatten.map do |relation_hash|
          Gitlab::ImportExport::RelationFactory.create(relation_sym: relation_type,
                                                       relation_hash: parsed_relation_hash(relation_hash, relation_type),
                                                       members_mapper: members_mapper,
                                                       user: @user,
                                                       project: restored_project)
        end.compact

        relation_hash_list.is_a?(Array) ? relation_array : relation_array.first
      end

      def parsed_relation_hash(relation_hash, relation_type)
        if RESTRICT_PROJECT_AND_GROUP.include?(relation_type)
          params = {}
          params['group_id'] = restored_project.group.try(:id) if relation_hash['group_id']
          params['project_id'] = restored_project.id if relation_hash['project_id']
        else
          params = { 'group_id' => restored_project.group.try(:id), 'project_id' => restored_project.id }
        end

        relation_hash.merge(params)
      end
    end
  end
end
