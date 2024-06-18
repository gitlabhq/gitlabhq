# frozen_string_literal: true

# AttributesPermitter builds a hash of permitted attributes for
# every model defined in import_export.yml that is used to validate and
# filter out any attributes that are not permitted when doing Project/Group Import
#
# Each model's list includes:
#   - attributes defined under included_attributes section
#   - associations defined under project/group tree
#   - methods defined under methods section
#
# Given the following import_export.yml example:
# ```
#   tree:
#     project:
#       - labels:
#         - :priorities
#   included_attributes:
#     labels:
#       - :title
#       - :description
#    methods:
#      labels:
#        - :type
# ```
#
# Produces a list of permitted attributes:
# ```
#   Gitlab::ImportExport::AttributesPermitter.new.permitted_attributes
#
#   => { labels: [:priorities, :title, :description, :type] }
# ```
#
# Filters out any other attributes from specific relation hash:
# ```
#   Gitlab::ImportExport::AttributesPermitter.new.permit(:labels, {id: 5, type: 'opened', description: 'test', sensitive_attribute: 'my_sensitive_attribute'})
#
#   => {:type=>"opened", :description=>"test"}
# ```
module Gitlab
  module ImportExport
    class AttributesPermitter
      attr_reader :permitted_attributes

      # We want to use AttributesCleaner for these relations instead, in the future this should be removed to make sure
      # we are using AttributesPermitter for every imported relation.
      DISABLED_RELATION_NAMES = %i[author issuable_sla].freeze

      def initialize(config: ImportExport::Config.new.to_h)
        @config = config
        @attributes_finder = Gitlab::ImportExport::AttributesFinder.new(config: @config)
        @permitted_attributes = {}

        build_permitted_attributes
      end

      def permit(relation_sym, relation_hash)
        permitted_attributes = permitted_attributes_for(relation_sym)

        relation_hash.select do |key, _|
          permitted_attributes.include?(key.to_sym)
        end
      end

      def permitted_attributes_for(relation_sym)
        @permitted_attributes[relation_sym] || []
      end

      def permitted_attributes_defined?(relation_sym)
        DISABLED_RELATION_NAMES.exclude?(relation_sym) && @attributes_finder.included_attributes.key?(relation_sym)
      end

      private

      def build_permitted_attributes
        build_associations
        build_attributes
        build_methods
      end

      # Deep traverse relations tree to build a list of allowed model relations
      def build_associations
        stack = @attributes_finder.tree.deep_merge(@attributes_finder.import_only_tree).to_a

        while stack.any?
          model_name, relations = stack.pop

          next unless relations.is_a?(Hash)

          add_permitted_attributes(model_name, relations.keys)

          stack.concat(relations.to_a)
        end

        @permitted_attributes
      end

      def build_attributes
        @attributes_finder.included_attributes.each do |model_name, attributes|
          add_permitted_attributes(model_name, attributes)
        end
      end

      def build_methods
        @attributes_finder.methods.each do |model_name, attributes|
          add_permitted_attributes(model_name, attributes)
        end
      end

      def add_permitted_attributes(model_name, attributes)
        @permitted_attributes[model_name] ||= []

        @permitted_attributes[model_name].concat(attributes) if attributes.any?
      end
    end
  end
end
