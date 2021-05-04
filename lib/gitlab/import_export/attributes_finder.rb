# frozen_string_literal: true

module Gitlab
  module ImportExport
    class AttributesFinder
      attr_reader :tree, :included_attributes, :excluded_attributes, :methods, :preloads, :export_reorders

      def initialize(config:)
        @tree = config[:tree] || {}
        @included_attributes = config[:included_attributes] || {}
        @excluded_attributes = config[:excluded_attributes] || {}
        @methods = config[:methods] || {}
        @preloads = config[:preloads] || {}
        @export_reorders = config[:export_reorders] || {}
      end

      def find_root(model_key)
        find(model_key, @tree[model_key])
      end

      def find_relations_tree(model_key)
        @tree[model_key]
      end

      def find_excluded_keys(klass_name)
        @excluded_attributes[klass_name.to_sym]&.map(&:to_s) || []
      end

      private

      def find(model_key, model_tree)
        {
          only: @included_attributes[model_key],
          except: @excluded_attributes[model_key],
          methods: @methods[model_key],
          include: resolve_model_tree(model_tree),
          preload: resolve_preloads(model_key, model_tree),
          export_reorder: @export_reorders[model_key]
        }.compact
      end

      def resolve_preloads(model_key, model_tree)
        model_tree
          .map { |submodel_key, submodel_tree| resolve_preload(model_key, submodel_key, submodel_tree) }
          .tap { |entries| entries.compact! }
          .to_h
          .deep_merge(@preloads[model_key].to_h)
          .presence
      end

      def resolve_preload(parent_model_key, model_key, model_tree)
        return if @methods[parent_model_key]&.include?(model_key)

        [model_key, resolve_preloads(model_key, model_tree)]
      end

      def resolve_model_tree(model_tree)
        return unless model_tree

        model_tree
          .map(&method(:resolve_model))
      end

      def resolve_model(model_key, model_tree)
        { model_key => find(model_key, model_tree) }
      end
    end
  end
end
