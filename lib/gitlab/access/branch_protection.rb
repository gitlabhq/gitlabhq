# frozen_string_literal: true

module Gitlab
  module Access
    # A wrapper around Integer based branch protection levels.
    #
    # This wrapper can be used to work with branch protection levels without
    # having to directly refer to the constants. For example, instead of this:
    #
    #     if access_level == Gitlab::Access::PROTECTION_DEV_CAN_PUSH
    #       ...
    #     end
    #
    # You can write this instead:
    #
    #     protection = BranchProtection.new(access_level)
    #
    #     if protection.developer_can_push?
    #       ...
    #     end
    class BranchProtection
      attr_reader :level

      # @param [Integer] level The branch protection level as an Integer.
      def initialize(level)
        @level = level
      end

      def any?
        level != PROTECTION_NONE
      end

      def developer_can_push?
        level == PROTECTION_DEV_CAN_PUSH
      end

      def developer_can_merge?
        level == PROTECTION_DEV_CAN_MERGE
      end

      def fully_protected?
        level == PROTECTION_FULL
      end
    end
  end
end
