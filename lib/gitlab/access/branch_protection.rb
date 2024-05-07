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

      def developer_can_initial_push?
        level == PROTECTION_DEV_CAN_INITIAL_PUSH
      end

      def developer_can_merge?
        level == PROTECTION_DEV_CAN_MERGE
      end

      def fully_protected?
        level == PROTECTION_FULL
      end

      def to_hash
        # translate the original integer values into a json payload
        # that matches the protected branches API:
        # https://docs.gitlab.com/ee/api/protected_branches.html#update-a-protected-branch
        case level
        when PROTECTION_NONE
          self.class.protection_none
        when PROTECTION_DEV_CAN_PUSH
          self.class.protection_partial
        when PROTECTION_FULL
          self.class.protected_fully
        when PROTECTION_DEV_CAN_MERGE
          self.class.protected_against_developer_pushes
        when PROTECTION_DEV_CAN_INITIAL_PUSH
          self.class.protected_after_initial_push
        end
      end

      class << self
        def protection_none
          {
            allowed_to_push: [{ 'access_level' => Gitlab::Access::DEVELOPER }],
            allowed_to_merge: [{ 'access_level' => Gitlab::Access::DEVELOPER }],
            allow_force_push: true,
            code_owner_approval_required: false,
            developer_can_initial_push: false
          }
        end

        def protection_partial
          {
            allowed_to_push: [{ 'access_level' => Gitlab::Access::DEVELOPER }],
            allowed_to_merge: [{ 'access_level' => Gitlab::Access::MAINTAINER }],
            allow_force_push: false,
            developer_can_initial_push: false
          }
        end

        def protected_fully
          {
            allowed_to_push: [{ 'access_level' => Gitlab::Access::MAINTAINER }],
            allowed_to_merge: [{ 'access_level' => Gitlab::Access::MAINTAINER }],
            allow_force_push: false,
            developer_can_initial_push: false
          }
        end

        def protected_against_developer_pushes
          {
            allowed_to_push: [{ 'access_level' => Gitlab::Access::MAINTAINER }],
            allowed_to_merge: [{ 'access_level' => Gitlab::Access::DEVELOPER }],
            allow_force_push: false,
            developer_can_initial_push: false
          }
        end

        def protected_after_initial_push
          {
            allowed_to_push: [{ 'access_level' => Gitlab::Access::MAINTAINER }],
            allowed_to_merge: [{ 'access_level' => Gitlab::Access::MAINTAINER }],
            allow_force_push: false,
            code_owner_approval_required: false,
            developer_can_initial_push: true
          }
        end
      end
    end
  end
end
