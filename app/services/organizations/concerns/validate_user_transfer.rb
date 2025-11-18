# frozen_string_literal: true

module Organizations
  module Concerns
    module ValidateUserTransfer
      # rubocop:disable CodeReuse/ActiveRecord -- Specific use for pluck
      # rubocop:disable Database/AvoidUsingPluckWithoutLimit -- Not used in IN clause
      def can_transfer_users?
        organization_ids = users.pluck(:organization_id)

        return false unless organization_ids.any?

        organization_ids.all?(group.organization_id)
      end
      # rubocop:enable CodeReuse/ActiveRecord
      # rubocop:enable Database/AvoidUsingPluckWithoutLimit

      def cannot_transfer_users_error
        s_("TransferOrganization|Cannot transfer users to a different organization " \
          "if all users do not belong to the same organization as the top-level group.")
      end
    end
  end
end
