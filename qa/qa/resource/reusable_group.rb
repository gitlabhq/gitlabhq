# frozen_string_literal: true

module QA
  module Resource
    class ReusableGroup < Group
      prepend Reusable

      def initialize
        super

        @path = "reusable_group"
        @description = "QA reusable group"
        @reuse_as = :default_group
      end

      # Confirms that the group can be reused
      #
      # @return [nil] returns nil unless an error is raised
      def validate_reuse_preconditions
        unless reused_path_unique?
          raise ResourceReuseError,
            "Reusable groups must have the same name. The group reused as #{reuse_as} has the path '#{path}' but it should be '#{self.class.resources[reuse_as].path}'"
        end
      end

      # Confirms that reuse of the resource did not change it in a way that breaks later reuse. This raises an error if
      # the current group path doesn't match the original path.
      def validate_reuse
        reload!

        if api_resource[:path] != @path
          raise ResourceReuseError, "The group now has the path '#{api_resource[:path]}' but it should be '#{path}'"
        end
      end

      # Checks if the group is being reused with the same path.
      #
      # @return [Boolean] true if the group's path is different from another group with the same reuse symbol (reuse_as)
      def reused_path_unique?
        return true unless self.class.resources.key?(reuse_as)

        self.class.resources[reuse_as].path == path
      end

      # Overrides QA::Resource::Group#remove_via_api! to log a debug message stating that removal will happen after
      # the suite completes rather than now.
      #
      # @return [nil]
      def remove_via_api!
        QA::Runtime::Logger.debug("#{self.class.name} - deferring removal until after suite")
      end
    end
  end
end
