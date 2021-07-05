# frozen_string_literal: true

module Gitlab
  module ImportExport
    class RelationTreeRestorer
      # Relations which cannot be saved at project level (and have a group assigned)
      GROUP_MODELS = [GroupLabel, Milestone, Epic].freeze

      attr_reader :user
      attr_reader :shared
      attr_reader :importable
      attr_reader :relation_reader

      def initialize( # rubocop:disable Metrics/ParameterLists
        user:, shared:, relation_reader:,
        members_mapper:, object_builder:,
        relation_factory:,
        reader:,
        importable:,
        importable_attributes:,
        importable_path:
      )
        @user = user
        @shared = shared
        @importable = importable
        @relation_reader = relation_reader
        @members_mapper = members_mapper
        @object_builder = object_builder
        @relation_factory = relation_factory
        @reader = reader
        @importable_attributes = importable_attributes
        @importable_path = importable_path
      end

      def restore
        ActiveRecord::Base.uncached do
          ActiveRecord::Base.no_touching do
            update_params!

            BulkInsertableAssociations.with_bulk_insert(enabled: @importable.instance_of?(::Project)) do
              fix_ci_pipelines_not_sorted_on_legacy_project_json!
              create_relations!
            end
          end
        end

        # ensure that we have latest version of the restore
        @importable.reload # rubocop:disable Cop/ActiveRecordAssociationReload

        true
      rescue StandardError => e
        @shared.error(e)
        false
      end

      private

      # Loops through the tree of models defined in import_export.yml and
      # finds them in the imported JSON so they can be instantiated and saved
      # in the DB. The structure and relationships between models are guessed from
      # the configuration yaml file too.
      # Finally, it updates each attribute in the newly imported project/group.
      def create_relations!
        relations.each(&method(:process_relation!))
      end

      def process_relation!(relation_key, relation_definition)
        @relation_reader.consume_relation(@importable_path, relation_key).each do |data_hash, relation_index|
          process_relation_item!(relation_key, relation_definition, relation_index, data_hash)
        end
      end

      def process_relation_item!(relation_key, relation_definition, relation_index, data_hash)
        relation_object = build_relation(relation_key, relation_definition, relation_index, data_hash)
        return unless relation_object
        return if importable_class == ::Project && group_model?(relation_object)

        relation_object.assign_attributes(importable_class_sym => @importable)

        import_failure_service.with_retry(action: 'relation_object.save!', relation_key: relation_key, relation_index: relation_index) do
          relation_object.save!
          log_relation_creation(@importable, relation_key, relation_object)
        end
      rescue StandardError => e
        import_failure_service.log_import_failure(
          source: 'process_relation_item!',
          relation_key: relation_key,
          relation_index: relation_index,
          exception: e)
      end

      def import_failure_service
        @import_failure_service ||= ImportFailureService.new(@importable)
      end

      def relations
        @relations ||=
          @reader
            .attributes_finder
            .find_relations_tree(importable_class_sym)
            .deep_stringify_keys
      end

      def update_params!
        params = @importable_attributes.except(*relations.keys.map(&:to_s))
        params = params.merge(present_override_params)

        # Cleaning all imported and overridden params
        params = Gitlab::ImportExport::AttributeCleaner.clean(
          relation_hash:  params,
          relation_class: importable_class,
          excluded_keys:  excluded_keys_for_relation(importable_class_sym))

        @importable.assign_attributes(params)
        @importable.drop_visibility_level! if importable_class == ::Project

        Gitlab::Timeless.timeless(@importable) do
          @importable.save!
        end
      end

      def present_override_params
        # we filter out the empty strings from the overrides
        # keeping the default values configured
        override_params&.transform_values do |value|
          value.is_a?(String) ? value.presence : value
        end&.compact
      end

      def override_params
        @importable_override_params ||= importable_override_params
      end

      def importable_override_params
        if @importable.respond_to?(:import_data)
          @importable.import_data&.data&.fetch('override_params', nil) || {}
        else
          {}
        end
      end

      def build_relations(relation_key, relation_definition, relation_index, data_hashes)
        data_hashes
          .map { |data_hash| build_relation(relation_key, relation_definition, relation_index, data_hash) }
          .tap { |entries| entries.compact! }
      end

      def build_relation(relation_key, relation_definition, relation_index, data_hash)
        # TODO: This is hack to not create relation for the author
        # Rather make `RelationFactory#set_note_author` to take care of that
        return data_hash if relation_key == 'author' || already_restored?(data_hash)

        # create relation objects recursively for all sub-objects
        relation_definition.each do |sub_relation_key, sub_relation_definition|
          transform_sub_relations!(data_hash, sub_relation_key, sub_relation_definition, relation_index)
        end

        relation = @relation_factory.create(**relation_factory_params(relation_key, relation_index, data_hash))

        if relation && !relation.valid?
          @shared.logger.warn(
            message: "[Project/Group Import] Invalid object relation built",
            relation_key: relation_key,
            relation_index: relation_index,
            relation_class: relation.class.name,
            error_messages: relation.errors.full_messages.join(". ")
          )
        end

        relation
      end

      # Since we update the data hash in place as we restore relation items,
      # and since we also de-duplicate items, we might encounter items that
      # have already been restored in a previous iteration.
      def already_restored?(relation_item)
        !relation_item.is_a?(Hash)
      end

      def transform_sub_relations!(data_hash, sub_relation_key, sub_relation_definition, relation_index)
        sub_data_hash = data_hash[sub_relation_key]
        return unless sub_data_hash

        # if object is a hash we can create simple object
        # as it means that this is 1-to-1 vs 1-to-many
        current_item =
          if sub_data_hash.is_a?(Array)
            build_relations(
              sub_relation_key,
              sub_relation_definition,
              relation_index,
              sub_data_hash).presence
          else
            build_relation(
              sub_relation_key,
              sub_relation_definition,
              relation_index,
              sub_data_hash)
          end

        if current_item
          data_hash[sub_relation_key] = current_item
        else
          data_hash.delete(sub_relation_key)
        end
      end

      def group_model?(relation_object)
        GROUP_MODELS.include?(relation_object.class) && relation_object.group_id
      end

      def excluded_keys_for_relation(relation)
        @reader.attributes_finder.find_excluded_keys(relation)
      end

      def importable_class
        @importable.class
      end

      def importable_class_sym
        importable_class.to_s.downcase.to_sym
      end

      def relation_factory_params(relation_key, relation_index, data_hash)
        {
          relation_index: relation_index,
          relation_sym: relation_key.to_sym,
          relation_hash: data_hash,
          importable: @importable,
          members_mapper: @members_mapper,
          object_builder: @object_builder,
          user: @user,
          excluded_keys: excluded_keys_for_relation(relation_key)
        }
      end

      # Temporary fix for https://gitlab.com/gitlab-org/gitlab/-/issues/27883 when import from legacy project.json
      # This should be removed once legacy JSON format is deprecated.
      # Ndjson export file will fix the order during project export.
      def fix_ci_pipelines_not_sorted_on_legacy_project_json!
        return unless relation_reader.legacy?

        relation_reader.sort_ci_pipelines_by_id
      end

      # Enable logging of each top-level relation creation when Importing
      # into a Group if feature flag is enabled
      def log_relation_creation(importable, relation_key, relation_object)
        root_ancestor_group = importable.try(:root_ancestor)

        return unless root_ancestor_group
        return unless root_ancestor_group.instance_of?(::Group)
        return unless Feature.enabled?(:log_import_export_relation_creation, root_ancestor_group)

        @shared.logger.info(
          importable_type: importable.class.to_s,
          importable_id: importable.id,
          relation_key: relation_key,
          relation_id: relation_object.id,
          author_id: relation_object.try(:author_id),
          message: '[Project/Group Import] Created new object relation'
        )
      end
    end
  end
end
