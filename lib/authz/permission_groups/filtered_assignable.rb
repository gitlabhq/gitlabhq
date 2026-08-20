# frozen_string_literal: true

module Authz
  module PermissionGroups
    # Overrides boundaries without mutating the memoized definition.
    class FilteredAssignable < SimpleDelegator
      def initialize(assignable, boundaries:)
        super(assignable)
        @boundaries = boundaries
      end

      attr_reader :boundaries
    end
  end
end
