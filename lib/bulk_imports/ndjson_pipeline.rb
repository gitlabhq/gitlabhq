# frozen_string_literal: true

module BulkImports
  module NdjsonPipeline
    extend ActiveSupport::Concern

    include Pipeline
    include Pipeline::IndexCacheStrategy

    included do
      file_extraction_pipeline!

      def transform(context, data)
        return unless data

        relation_hash, relation_index = data

        return unless relation_hash

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
            import_source: Import::SOURCE_DIRECT_TRANSFER
          )
        end

        relation_object.assign_attributes(portable_class_sym => portable)
        relation_object
      end

      def load(_context, object)
        return unless object

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
      end

      def deep_transform_relation!(relation_hash, relation_key, relation_definition, &block)
        relation_key = relation_key_override(relation_key)

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
        @members_mapper ||= BulkImports::UsersMapper.new(context: context)
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
    end

    def persist_relation(attributes)
      relation_factory.create(**attributes)
    end
  end
end
