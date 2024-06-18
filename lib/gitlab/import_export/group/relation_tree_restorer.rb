# frozen_string_literal: true

module Gitlab
  module ImportExport
    module Group
      class RelationTreeRestorer
        include Gitlab::Utils::StrongMemoize

        def initialize( # rubocop:disable Metrics/ParameterLists
          user:,
          shared:,
          relation_reader:,
          members_mapper:,
          object_builder:,
          relation_factory:,
          reader:,
          importable:,
          importable_attributes:,
          importable_path:,
          skip_on_duplicate_iid: false
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
          @skip_on_duplicate_iid = skip_on_duplicate_iid
        end

        def restore
          bulk_insert_without_cache_or_touch do
            create_relations!
          end
        end

        def restore_single_relation(relation_key)
          # NO-OP. This is currently only available for file-based project import.
        end

        private

        attr_reader :user, :relation_factory
        alias_method :current_user, :user

        def bulk_insert_without_cache_or_touch
          Gitlab::Database.all_uncached do
            ActiveRecord::Base.no_touching do
              update_params!

              BulkInsertableAssociations.with_bulk_insert(enabled: bulk_insert_enabled) do
                yield
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

        def bulk_insert_enabled
          false
        end

        def skip_on_duplicate_iid?
          @skip_on_duplicate_iid
        end

        # Loops through the tree of models defined in import_export.yml and
        # finds them in the imported JSON so they can be instantiated and saved
        # in the DB. The structure and relationships between models are guessed from
        # the configuration yaml file too.
        # Finally, it updates each attribute in the newly imported project/group.
        def create_relations!
          relations.each do |relation_key, relation_definition|
            process_relation!(relation_key, relation_definition)
          end
        end

        def process_relation!(relation_key, relation_definition)
          @relation_reader.consume_relation(@importable_path, relation_key).each do |data_hash, relation_index|
            process_relation_item!(relation_key, relation_definition, relation_index, data_hash)
          end
        end

        def process_relation_item!(relation_key, relation_definition, relation_index, data_hash)
          relation_object = build_relation(relation_key, relation_definition, relation_index, data_hash)

          return unless relation_object
          return if relation_invalid_for_importable?(relation_object)
          return if skip_on_duplicate_iid? && previously_imported?(relation_object, relation_key)

          relation_object.assign_attributes(importable_class_sym => @importable)

          save_relation_object(relation_object, relation_key, relation_definition, relation_index)
        rescue StandardError => e
          import_failure_service.log_import_failure(
            source: 'process_relation_item!',
            relation_key: relation_key,
            relation_index: relation_index,
            exception: e,
            external_identifiers: external_identifiers(data_hash))
        end

        def previously_imported?(relation_object, relation_key)
          existing_iids(relation_key).key?(relation_object.iid)
        end

        # Generate the list of existing IIDs as a hash.
        # { issues: { 1: true, 2: true, ... }}
        # A hash is used rather than returning the array of IDs because lookup
        # performance is greatly improved.
        def existing_iids(relation_key)
          strong_memoize_with(:existing_iids, relation_key) do
            case relation_key
            when 'issues' then @importable.issues.pluck(:iid)
            when 'milestones' then @importable.milestones.pluck(:iid)
            when 'ci_pipelines' then @importable.ci_pipelines.pluck(:iid)
            when 'merge_requests' then @importable.merge_requests.pluck(:iid)
            end.index_with(true)
          end
        end

        def save_relation_object(relation_object, relation_key, relation_definition, relation_index)
          if relation_object.new_record?
            saver = Gitlab::ImportExport::Base::RelationObjectSaver.new(
              relation_object: relation_object,
              relation_key: relation_key,
              relation_definition: relation_definition,
              importable: @importable
            )

            saver.execute

            log_invalid_subrelations(saver.invalid_subrelations, relation_key)
          else
            if relation_object.invalid?
              Gitlab::Import::Errors.merge_nested_errors(relation_object)

              raise(ActiveRecord::RecordInvalid, relation_object)
            end

            import_failure_service.with_retry(action: 'relation_object.save!', relation_key: relation_key, relation_index: relation_index) do
              relation_object.save!
            end
          end

          log_relation_creation(@importable, relation_key, relation_object)
        end

        def import_failure_service
          @import_failure_service ||= ImportFailureService.new(@importable)
        end

        def relations
          @relations ||=
            @reader
              .attributes_finder
              .find_relations_tree(importable_class_sym, include_import_only_tree: true)
              .deep_stringify_keys
        end

        def update_params!
          params = @importable_attributes.except(*relations.keys.map(&:to_s))
          params = params.merge(present_override_params)
          params = filter_attributes(params)

          @importable.assign_attributes(params)

          modify_attributes

          @importable.save!(touch: false)
        end

        def filter_attributes(params)
          if attributes_permitter.permitted_attributes_defined?(importable_class_sym)
            attributes_permitter.permit(importable_class_sym, params)
          else
            Gitlab::ImportExport::AttributeCleaner.clean(
              relation_hash: params,
              relation_class: importable_class,
              excluded_keys: excluded_keys_for_relation(importable_class_sym))
          end
        end

        def attributes_permitter
          @attributes_permitter ||= Gitlab::ImportExport::AttributesPermitter.new
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

        def modify_attributes
          # no-op to be overridden on inheritance
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

          relation = persist_relation(**relation_factory_params(relation_key, relation_index, data_hash))

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

        def relation_invalid_for_importable?(_relation_object)
          false
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
            excluded_keys: excluded_keys_for_relation(relation_key),
            import_source: ::Import::SOURCE_GROUP_EXPORT_IMPORT
          }
        end

        # Enable logging of each top-level relation creation when Importing into a Group
        def log_relation_creation(importable, relation_key, relation_object)
          root_ancestor_group = importable.try(:root_ancestor)

          return unless root_ancestor_group
          return unless root_ancestor_group.instance_of?(::Group)

          @shared.logger.info(
            importable_type: importable.class.to_s,
            importable_id: importable.id,
            relation_key: relation_key,
            relation_id: relation_object.id,
            author_id: relation_object.try(:author_id),
            message: '[Project/Group Import] Created new object relation'
          )
        end

        def log_invalid_subrelations(invalid_subrelations, relation_key)
          invalid_subrelations.flatten.each do |record|
            Gitlab::Import::Errors.merge_nested_errors(record)

            @shared.logger.info(
              message: '[Project/Group Import] Invalid subrelation',
              importable_column_name => @importable.id,
              relation_key: relation_key,
              error_messages: record.errors.full_messages.to_sentence
            )

            ::ImportFailure.create(
              source: 'RelationTreeRestorer#save_relation_object',
              relation_key: relation_key,
              exception_class: 'ActiveRecord::RecordInvalid',
              exception_message: record.errors.full_messages.to_sentence,
              correlation_id_value: Labkit::Correlation::CorrelationId.current_or_new_id,
              importable_column_name => @importable.id
            )
          end
        end

        def importable_column_name
          @column_name ||= @importable.class.reflect_on_association(:import_failures).foreign_key.to_sym
        end

        def external_identifiers(data_hash)
          { iid: data_hash['iid'] }.compact
        end

        def persist_relation(attributes)
          @relation_factory.create(**attributes)
        end
      end
    end
  end
end

Gitlab::ImportExport::Group::RelationTreeRestorer.prepend_mod
