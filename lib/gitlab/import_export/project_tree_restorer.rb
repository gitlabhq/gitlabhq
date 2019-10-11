# frozen_string_literal: true

module Gitlab
  module ImportExport
    class ProjectTreeRestorer
      # Relations which cannot be saved at project level (and have a group assigned)
      GROUP_MODELS = [GroupLabel, Milestone].freeze

      attr_reader :user
      attr_reader :shared
      attr_reader :project

      def initialize(user:, shared:, project:)
        @path = File.join(shared.export_path, 'project.json')
        @user = user
        @shared = shared
        @project = project
        @saved = true
      end

      def restore
        begin
          @tree_hash = read_tree_hash
        rescue => e
          Rails.logger.error("Import/Export error: #{e.message}") # rubocop:disable Gitlab/RailsLogger
          raise Gitlab::ImportExport::Error.new('Incorrect JSON format')
        end

        @project_members = @tree_hash.delete('project_members')

        RelationRenameService.rename(@tree_hash)

        ActiveRecord::Base.uncached do
          ActiveRecord::Base.no_touching do
            update_project_params!
            create_relations
          end
        end

        # ensure that we have latest version of the restore
        @project.reload # rubocop:disable Cop/ActiveRecordAssociationReload

        true
      rescue => e
        @shared.error(e)
        false
      end

      private

      def read_tree_hash
        json = IO.read(@path)
        ActiveSupport::JSON.decode(json)
      end

      def members_mapper
        @members_mapper ||= Gitlab::ImportExport::MembersMapper.new(exported_members: @project_members,
                                                                    user: @user,
                                                                    project: @project)
      end

      # A Hash of the imported merge request ID -> imported ID.
      def merge_requests_mapping
        @merge_requests_mapping ||= {}
      end

      # Loops through the tree of models defined in import_export.yml and
      # finds them in the imported JSON so they can be instantiated and saved
      # in the DB. The structure and relationships between models are guessed from
      # the configuration yaml file too.
      # Finally, it updates each attribute in the newly imported project.
      def create_relations
        project_relations.each do |relation_key, relation_definition|
          relation_key_s = relation_key.to_s

          if relation_definition.present?
            create_sub_relations(relation_key_s, relation_definition, @tree_hash)
          elsif @tree_hash[relation_key_s].present?
            save_relation_hash(relation_key_s, @tree_hash[relation_key_s])
          end
        end

        @project.merge_requests.set_latest_merge_request_diff_ids!

        @saved
      end

      def save_relation_hash(relation_key, relation_hash_batch)
        relation_hash = create_relation(relation_key, relation_hash_batch)

        remove_group_models(relation_hash) if relation_hash.is_a?(Array)

        @saved = false unless @project.append_or_update_attribute(relation_key, relation_hash)

        save_id_mappings(relation_key, relation_hash_batch, relation_hash)

        @project.reset
      end

      # Older, serialized CI pipeline exports may only have a
      # merge_request_id and not the full hash of the merge request. To
      # import these pipelines, we need to preserve the mapping between
      # the old and new the merge request ID.
      def save_id_mappings(relation_key, relation_hash_batch, relation_hash)
        return unless relation_key == 'merge_requests'

        relation_hash = Array(relation_hash)

        Array(relation_hash_batch).each_with_index do |raw_data, index|
          merge_requests_mapping[raw_data['id']] = relation_hash[index]['id']
        end
      end

      # Remove project models that became group models as we found them at group level.
      # This no longer required saving them at the root project level.
      # For example, in the case of an existing group label that matched the title.
      def remove_group_models(relation_hash)
        relation_hash.reject! do |value|
          GROUP_MODELS.include?(value.class) && value.group_id
        end
      end

      def remove_feature_dependent_sub_relations!(_relation_item)
        # no-op
      end

      def project_relations
        @project_relations ||= reader.attributes_finder.find_relations_tree(:project)
      end

      def update_project_params!
        Gitlab::Timeless.timeless(@project) do
          project_params = @tree_hash.reject do |key, value|
            project_relations.include?(key.to_sym)
          end

          project_params = project_params.merge(present_project_override_params)

          # Cleaning all imported and overridden params
          project_params = Gitlab::ImportExport::AttributeCleaner.clean(
            relation_hash: project_params,
            relation_class: Project,
            excluded_keys: excluded_keys_for_relation(:project))

          @project.assign_attributes(project_params)
          @project.drop_visibility_level!
          @project.save!
        end
      end

      def present_project_override_params
        # we filter out the empty strings from the overrides
        # keeping the default values configured
        project_override_params.transform_values do |value|
          value.is_a?(String) ? value.presence : value
        end.compact
      end

      def project_override_params
        @project_override_params ||= @project.import_data&.data&.fetch('override_params', nil) || {}
      end

      # Given a relation hash containing one or more models and its relationships,
      # loops through each model and each object from a model type and
      # and assigns its correspondent attributes hash from +tree_hash+
      # Example:
      # +relation_key+ issues, loops through the list of *issues* and for each individual
      # issue, finds any subrelations such as notes, creates them and assign them back to the hash
      #
      # Recursively calls this method if the sub-relation is a hash containing more sub-relations
      def create_sub_relations(relation_key, relation_definition, tree_hash, save: true)
        return if tree_hash[relation_key].blank?

        tree_array = [tree_hash[relation_key]].flatten

        # Avoid keeping a possible heavy object in memory once we are done with it
        while relation_item = tree_array.shift
          remove_feature_dependent_sub_relations!(relation_item)

          # The transaction at this level is less speedy than one single transaction
          # But we can't have it in the upper level or GC won't get rid of the AR objects
          # after we save the batch.
          Project.transaction do
            process_sub_relation(relation_key, relation_definition, relation_item)

            # For every subrelation that hangs from Project, save the associated records altogether
            # This effectively batches all records per subrelation item, only keeping those in memory
            # We have to keep in mind that more batch granularity << Memory, but >> Slowness
            if save
              save_relation_hash(relation_key, [relation_item])
              tree_hash[relation_key].delete(relation_item)
            end
          end
        end

        tree_hash.delete(relation_key) if save
      end

      def process_sub_relation(relation_key, relation_definition, relation_item)
        relation_definition.each do |sub_relation_key, sub_relation_definition|
          # We just use author to get the user ID, do not attempt to create an instance.
          next if sub_relation_key == :author

          sub_relation_key_s = sub_relation_key.to_s

          # create dependent relations if present
          if sub_relation_definition.present?
            create_sub_relations(sub_relation_key_s, sub_relation_definition, relation_item, save: false)
          end

          # transform relation hash to actual object
          sub_relation_hash = relation_item[sub_relation_key_s]
          if sub_relation_hash.present?
            relation_item[sub_relation_key_s] = create_relation(sub_relation_key, sub_relation_hash)
          end
        end
      end

      def create_relation(relation_key, relation_hash_list)
        relation_array = [relation_hash_list].flatten.map do |relation_hash|
          Gitlab::ImportExport::RelationFactory.create(
            relation_sym: relation_key.to_sym,
            relation_hash: relation_hash,
            members_mapper: members_mapper,
            merge_requests_mapping: merge_requests_mapping,
            user: @user,
            project: @project,
            excluded_keys: excluded_keys_for_relation(relation_key))
        end.compact

        relation_hash_list.is_a?(Array) ? relation_array : relation_array.first
      end

      def reader
        @reader ||= Gitlab::ImportExport::Reader.new(shared: @shared)
      end

      def excluded_keys_for_relation(relation)
        reader.attributes_finder.find_excluded_keys(relation)
      end
    end
  end
end

Gitlab::ImportExport::ProjectTreeRestorer.prepend_if_ee('::EE::Gitlab::ImportExport::ProjectTreeRestorer')
