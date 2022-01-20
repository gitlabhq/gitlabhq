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
        @name = "reusable_project"
        @reuse_as = :default_project
        @initialize_with_readme = true
      end

      # Confirms that the project can be reused
      #
      # @return [nil] returns nil unless an error is raised
      def validate_reuse_preconditions
        unless reused_name_unique?
          raise ResourceReuseError,
            "Reusable projects must have the same name. The project reused as #{reuse_as} has the name '#{name}' but it should be '#{self.class.resources[reuse_as].name}'"
        end
      end

      # Checks if the project is being reused with the same name.
      #
      # @return [Boolean] true if the project's name is different from another project with the same reuse symbol (reuse_as)
      def reused_name_unique?
        return true unless self.class.resources.key?(reuse_as)

        self.class.resources[reuse_as].name == name
      end

      # Overrides QA::Resource::Project#remove_via_api! to log a debug message stating that removal will happen after
      # the suite completes rather than now.
      #
      # @return [nil]
      def remove_via_api!
        QA::Runtime::Logger.debug("#{self.class.name} - deferring removal until after suite")
      end
    end
  end
end
