# frozen_string_literal: true

module QA
  module Resource
    class ReusableProject < Project
      prepend Reusable

      attribute :group do
        ReusableGroup.fabricate_via_api! do |resource|
          resource.api_client = api_client
        end
      end

      def initialize
        super

        @add_name_uuid = false
        @name = @path = 'reusable_project'
        @reuse_as = :default_project
        @initialize_with_readme = true
      end

      private

      # Creates a new project that can be compared to a reused project, using the attributes of the original. Attributes
      # that must be unique (path and name) are replaced with new unique values.
      #
      # @return [QA::Resource] a new instance of Resource::ReusableProject that should be a copy of the original resource
      def reference_resource
        attributes = self.class.resources[reuse_as][:attributes]
        name = "reference_resource_#{SecureRandom.hex(8)}_for_#{attributes.delete(:name)}"

        Project.fabricate_via_api! do |project|
          self.class.resources[reuse_as][:attributes].each do |attribute_name, attribute_value|
            project.instance_variable_set("@#{attribute_name}", attribute_value) if attribute_value
          end
          project.name = name
          project.path = name
          project.path_with_namespace = "#{project.group.full_path}/#{project.name}"
        end
      end

      # The attributes of the resource that should be the same whenever a test wants to reuse a project.
      #
      # @return [Array<Symbol>] the attribute names.
      def unique_identifiers
        [:name, :path]
      end
    end
  end
end
