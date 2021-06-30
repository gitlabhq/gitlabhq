# frozen_string_literal: true

module BulkImports
  module NdjsonPipeline
    extend ActiveSupport::Concern

    include Pipeline

    included do
      ndjson_pipeline!

      def transform(context, data)
        relation_hash, relation_index = data
        relation_definition = import_export_config.top_relation_tree(relation)

        deep_transform_relation!(relation_hash, relation, relation_definition) do |key, hash|
          Gitlab::ImportExport::Group::RelationFactory.create(
            relation_index: relation_index,
            relation_sym: key.to_sym,
            relation_hash: hash,
            importable: context.portable,
            members_mapper: members_mapper,
            object_builder: object_builder,
            user: context.current_user,
            excluded_keys: import_export_config.relation_excluded_keys(key)
          )
        end
      end

      def load(_, object)
        return unless object

        object.save! unless object.persisted?
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
        extractor.remove_tmp_dir if extractor.respond_to?(:remove_tmp_dir)
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

      def relation
        self.class.relation
      end

      def members_mapper
        @members_mapper ||= BulkImports::UsersMapper.new(context: context)
      end
    end
  end
end
