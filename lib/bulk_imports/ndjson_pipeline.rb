# frozen_string_literal: true

module BulkImports
  module NdjsonPipeline
    extend ActiveSupport::Concern

    include Pipeline
    include Pipeline::IndexCacheStrategy

    IGNORE_PLACEHOLDER_USER_CREATION = {
      'approvals' => ['user_id'],
      'bridges' => ['user_id'],
      'builds' => ['user_id'],
      'ci_pipelines' => ['user_id'],
      'events' => ['author_id'],
      'generic_commit_statuses' => ['user_id'],
      'issues' => ['last_edited_by_id'],
      'notes' => %w[updated_by_id resolved_by_id]
    }.freeze

    included do
      file_extraction_pipeline!

      def transform(context, data)
        return unless data

        relation_hash, relation_index = data

        return unless relation_hash

        original_users_map = {}.compare_by_identity

        relation_object = deep_transform_relation!(relation_hash, relation, relation_definition) do |key, hash|
          persist_relation(
            relation_index: relation_index,
            relation_sym: key.to_sym,
            relation_hash: hash,
            importable: context.portable,
            members_mapper: members_mapper,
            object_builder: object_builder,
            user: context.current_user,
            excluded_keys: import_export_config.relation_excluded_keys(key),
            import_source: Import::SOURCE_DIRECT_TRANSFER,
            original_users_map: original_users_map,
            rewrite_mentions: context.importer_user_mapping_enabled?
          )
        end

        relation_object.assign_attributes(portable_class_sym => portable)

        [relation_object, original_users_map]
      end

      def load(_context, data)
        object, original_users_map = data

        return unless object

        begin
          if object.new_record?
            saver = Gitlab::ImportExport::Base::RelationObjectSaver.new(
              relation_object: object,
              relation_key: relation,
              relation_definition: relation_definition,
              importable: portable
            )

            saver.execute

            capture_invalid_subrelations(saver.invalid_subrelations)
          else
            if object.invalid?
              Gitlab::Import::Errors.merge_nested_errors(object)

              raise(ActiveRecord::RecordInvalid, object)
            end

            object.save!
          end

        ensure
          push_placeholder_references(original_users_map) if context.importer_user_mapping_enabled?
        end
      end

      def deep_transform_relation!(relation_hash, relation_key, relation_definition, &block)
        relation_definition.each do |sub_relation_key, sub_relation_definition|
          sub_relation = relation_hash[sub_relation_key]

          next unless sub_relation

          current_item =
            if sub_relation.is_a?(Array)
              sub_relation
                .map { |entry| deep_transform_relation!(entry, sub_relation_key, sub_relation_definition, &block) }
                .tap { |entry| entry.compact! }
                .presence
            else
              deep_transform_relation!(sub_relation, sub_relation_key, sub_relation_definition, &block)
            end

          if current_item
            relation_hash[sub_relation_key] = current_item
          else
            relation_hash.delete(sub_relation_key)
          end
        end

        # Create Import::SourceUser objects during the transformation
        # step if they were not created during the MemberPipeline.
        create_import_source_users(relation_key, relation_hash) if context.importer_user_mapping_enabled?

        yield(relation_key, relation_hash)
      end

      def after_run(_)
        extractor.remove_tmpdir if extractor.respond_to?(:remove_tmpdir)
      end

      def relation_class(relation_key)
        relation_key.to_s.classify.constantize
      rescue NameError
        relation_key.to_s.constantize
      end

      def relation_key_override(relation_key)
        relation_key_overrides[relation_key.to_sym]&.to_s || relation_key
      end

      def relation_key_overrides
        "Gitlab::ImportExport::#{portable.class}::RelationFactory::OVERRIDES".constantize
      end

      def object_builder
        "Gitlab::ImportExport::#{portable.class}::ObjectBuilder".constantize
      end

      def relation_factory
        "Gitlab::ImportExport::#{portable.class}::RelationFactory".constantize
      end

      def relation
        self.class.relation
      end

      def members_mapper
        @members_mapper ||= if context.importer_user_mapping_enabled?
                              Import::BulkImports::SourceUsersMapper.new(context: context)
                            else
                              UsersMapper.new(context: context)
                            end
      end

      def source_user_mapper
        context.source_user_mapper
      end

      def portable_class_sym
        portable.class.to_s.downcase.to_sym
      end

      def relation_definition
        import_export_config.top_relation_tree(relation)
      end

      def capture_invalid_subrelations(invalid_subrelations)
        invalid_subrelations.each do |record|
          BulkImports::Failure.create(
            bulk_import_entity_id: tracker.entity.id,
            pipeline_class: tracker.pipeline_name,
            exception_class: 'RecordInvalid',
            exception_message: record.errors.full_messages.to_sentence,
            correlation_id_value: Labkit::Correlation::CorrelationId.current_or_new_id,
            subrelation: record.class.to_s
          )
        end
      end

      # Creates an Import::SourceUser objects for each source_user_identifier
      # found in the relation_hash and associate it with the ImportUser.
      #
      # For example, if the relation_hash is:
      #
      # {
      #   "title": "Title",
      #   "author_id": 100,
      #   "updated_by_id": 101
      # }
      #
      # Import::SourceUser records with source_user_identifier 100 and 101 will be
      # created if none are found in the database, along with a placeholder user
      # for each record.
      def create_import_source_users(relation_key, relation_hash)
        relation_factory::USER_REFERENCES.each do |reference|
          next unless relation_hash[reference]

          # Skip creating placeholder users for these relations.
          # These may reference users that no longer exist in the source instance
          # as they lack a foreign key constraint.
          next if IGNORE_PLACEHOLDER_USER_CREATION[relation_key]&.include?(reference)

          source_user_mapper.find_or_create_source_user(
            source_name: nil,
            source_username: nil,
            source_user_identifier: relation_hash[reference]
          )
        end
      end

      # Pushes a placeholder reference for each source_user_identifier contained in
      # the original_users_map.
      #
      # The `original_users_map` is a hash where the key is an object built by the
      # RelationFactory, and the value is another hash. This second hash maps
      # attributes that reference user IDs to the user IDs from the source instance,
      # essentially the information present in the NDJSON file.
      #
      # For example, below is an example of `original_users_map`:
      #
      # {
      #   #<Issue:0x0001: {"author_id"=>1, "updated_by_id"=>2, "last_edited_by_id"=>2, "closed_by_id"=>2 },
      #   #<ResourceStateEvent:0x0002: {"user_id"=>1"]},
      #   #<ResourceStateEvent:0x0003: {"user_id"=>2"]},
      #   #<ResourceStateEvent:0x0004: {"user_id"=>2"]},
      #   #<Note:0x0005: {"author_id"=>1"]},
      #   #<Note:0x0006: {"author_id"=>2"]}
      # }
      def push_placeholder_references(original_users_map)
        original_users_map.each do |object, user_references|
          next unless object.persisted?

          user_references.each do |attribute, source_user_identifier|
            source_user = source_user_mapper.find_source_user(source_user_identifier)
            next unless source_user

            # Do not create a reference if the object is already associated
            # with a real user.
            next if source_user.accepted_status? && object[attribute] == source_user.reassign_to_user_id

            ::Import::PlaceholderReferences::PushService.from_record(
              import_source: ::Import::SOURCE_DIRECT_TRANSFER,
              import_uid: context.bulk_import_id,
              record: object,
              source_user: source_user,
              user_reference_column: attribute.to_sym
            ).execute
          end
        end
      end
    end

    def persist_relation(attributes)
      relation_factory.create(**attributes)
    end
  end
end
