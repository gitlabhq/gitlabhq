# frozen_string_literal: true

module BulkImports
  module NdjsonPipeline
    extend ActiveSupport::Concern

    include Pipeline

    included do
      ndjson_pipeline!

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
    end
  end
end
