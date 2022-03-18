# frozen_string_literal: true

module QA
  module Resource
    class ReusableGroup < Group
      prepend Reusable

      def initialize
        super

        @name = @path = QA::Runtime::Env.reusable_group_path
        @description = "QA reusable group"
        @reuse_as = :default_group
      end

      private

      # Creates a new group that can be compared to a reused group, using the attributes of the original. Attributes that
      # must be unique (path and name) are replaced with new unique values.
      #
      # @return [QA::Resource] a new instance of Resource::ReusableGroup that should be a copy of the original resource
      def reference_resource
        attributes = self.class.resources[reuse_as][:attributes]
        name = "ref#{SecureRandom.hex(8)}_#{attributes.delete(:path)}"[0...MAX_NAME_LENGTH]

        Group.fabricate_via_api! do |resource|
          self.class.resources[reuse_as][:attributes].each do |attribute_name, attribute_value|
            resource.instance_variable_set("@#{attribute_name}", attribute_value) if attribute_value
          end
          resource.path = name
          resource.name = name
        end
      end

      # The attributes of the resource that should be the same whenever a test wants to reuse a group.
      #
      # @return [Array<Symbol>] the attribute names.
      def unique_identifiers
        [:name, :path]
      end
    end
  end
end
