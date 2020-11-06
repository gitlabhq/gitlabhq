# frozen_string_literal: true

module BulkImports
  module Pipeline
    class Context
      include Gitlab::Utils::LazyAttributes

      Attribute = Struct.new(:name, :type)

      PIPELINE_ATTRIBUTES = [
        Attribute.new(:current_user, User),
        Attribute.new(:entity, ::BulkImports::Entity),
        Attribute.new(:configuration, ::BulkImports::Configuration)
      ].freeze

      def initialize(args)
        assign_attributes(args)
      end

      private

      PIPELINE_ATTRIBUTES.each do |attr|
        lazy_attr_reader attr.name, type: attr.type
      end

      def assign_attributes(values)
        values.slice(*PIPELINE_ATTRIBUTES.map(&:name)).each do |name, value|
          instance_variable_set("@#{name}", value)
        end
      end
    end
  end
end
