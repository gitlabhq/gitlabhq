# frozen_string_literal: true

module Gitlab
  module ImportExport
    class AttributesFinder
      def initialize(config:)
        @tree = config[:tree] || {}
        @included_attributes = config[:included_attributes] || {}
        @excluded_attributes = config[:excluded_attributes] || {}
        @methods = config[:methods] || {}
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
          include: resolve_model_tree(model_tree)
        }.compact
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
