# frozen_string_literal: true

module Gitlab
  module ImportExport
    class RelationTreeRestorer
      # Relations which cannot be saved at project level (and have a group assigned)
      GROUP_MODELS = [GroupLabel, Milestone].freeze

      attr_reader :user
      attr_reader :shared
      attr_reader :importable
      attr_reader :tree_hash

      def initialize(user:, shared:, importable:, tree_hash:, members_mapper:, relation_factory:, reader:)
        @user = user
        @shared = shared
        @importable = importable
        @tree_hash = tree_hash
        @members_mapper = members_mapper
        @relation_factory = relation_factory
        @reader = reader
      end

      def restore
        ActiveRecord::Base.uncached do
          ActiveRecord::Base.no_touching do
            update_params!
            create_relations!
          end
        end

        # ensure that we have latest version of the restore
        @importable.reload # rubocop:disable Cop/ActiveRecordAssociationReload

        true
      rescue => e
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
        data_hashes = @tree_hash.delete(relation_key)
        return unless data_hashes

        # we do not care if we process array or hash
        data_hashes = [data_hashes] unless data_hashes.is_a?(Array)

        relation_index = 0

        # consume and remove objects from memory
        while data_hash = data_hashes.shift
          process_relation_item!(relation_key, relation_definition, relation_index, data_hash)
          relation_index += 1
        end
      end

      def process_relation_item!(relation_key, relation_definition, relation_index, data_hash)
        relation_object = build_relation(relation_key, relation_definition, data_hash)
        return unless relation_object
        return if importable_class == Project && group_model?(relation_object)

        relation_object.assign_attributes(importable_class_sym => @importable)
        relation_object.save!

        save_id_mapping(relation_key, data_hash, relation_object)
      rescue => e
        log_import_failure(relation_key, relation_index, e)
      end

      def log_import_failure(relation_key, relation_index, exception)
        Gitlab::ErrorTracking.track_exception(exception,
          project_id: @importable.id, relation_key: relation_key, relation_index: relation_index)

        ImportFailure.create(
          project: @importable,
          relation_key: relation_key,
          relation_index: relation_index,
          exception_class: exception.class.to_s,
          exception_message: exception.message.truncate(255),
          correlation_id_value: Labkit::Correlation::CorrelationId.current_or_new_id
        )
      end

      # Older, serialized CI pipeline exports may only have a
      # merge_request_id and not the full hash of the merge request. To
      # import these pipelines, we need to preserve the mapping between
      # the old and new the merge request ID.
      def save_id_mapping(relation_key, data_hash, relation_object)
        return unless importable_class == Project
        return unless relation_key == 'merge_requests'

        merge_requests_mapping[data_hash['id']] = relation_object.id
      end

      def relations
        @relations ||=
          @reader
            .attributes_finder
            .find_relations_tree(importable_class_sym)
            .deep_stringify_keys
      end

      def update_params!
        params = @tree_hash.reject do |key, _|
          relations.include?(key)
        end

        params = params.merge(present_override_params)

        # Cleaning all imported and overridden params
        params = Gitlab::ImportExport::AttributeCleaner.clean(
          relation_hash:  params,
          relation_class: importable_class,
          excluded_keys:  excluded_keys_for_relation(importable_class_sym))

        @importable.assign_attributes(params)
        @importable.drop_visibility_level! if importable_class == Project

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

      def build_relations(relation_key, relation_definition, data_hashes)
        data_hashes.map do |data_hash|
          build_relation(relation_key, relation_definition, data_hash)
        end.compact
      end

      def build_relation(relation_key, relation_definition, data_hash)
        # TODO: This is hack to not create relation for the author
        # Rather make `RelationFactory#set_note_author` to take care of that
        return data_hash if relation_key == 'author'

        # create relation objects recursively for all sub-objects
        relation_definition.each do |sub_relation_key, sub_relation_definition|
          transform_sub_relations!(data_hash, sub_relation_key, sub_relation_definition)
        end

        @relation_factory.create(relation_factory_params(relation_key, data_hash))
      end

      def transform_sub_relations!(data_hash, sub_relation_key, sub_relation_definition)
        sub_data_hash = data_hash[sub_relation_key]
        return unless sub_data_hash

        # if object is a hash we can create simple object
        # as it means that this is 1-to-1 vs 1-to-many
        sub_data_hash =
          if sub_data_hash.is_a?(Array)
            build_relations(
              sub_relation_key,
              sub_relation_definition,
              sub_data_hash).presence
          else
            build_relation(
              sub_relation_key,
              sub_relation_definition,
              sub_data_hash)
          end

        # persist object(s) or delete from relation
        if sub_data_hash
          data_hash[sub_relation_key] = sub_data_hash
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

      # A Hash of the imported merge request ID -> imported ID.
      def merge_requests_mapping
        @merge_requests_mapping ||= {}
      end

      def relation_factory_params(relation_key, data_hash)
        base_params = {
          relation_sym:   relation_key.to_sym,
          relation_hash:  data_hash,
          members_mapper: @members_mapper,
          user:           @user,
          excluded_keys:  excluded_keys_for_relation(relation_key)
        }

        base_params[:merge_requests_mapping] = merge_requests_mapping if importable_class == Project
        base_params[importable_class_sym] = @importable
        base_params
      end
    end
  end
end
