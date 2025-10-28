# frozen_string_literal: true

module Organizations
  module Groups
    class TransferWorker
      include ApplicationWorker

      data_consistency :sticky
      idempotent!

      feature_category :organization
      urgency :low

      defer_on_database_health_signal :gitlab_main, [:groups], 1.minute

      def perform(args)
        group_id = args['group_id']
        organization_id = args['organization_id']
        current_user_id = args['current_user_id']

        group = Group.find_by_id(group_id)
        return unless group

        organization = Organization.find_by_id(organization_id)
        return unless organization

        current_user = User.find_by_id(current_user_id)
        return unless current_user

        Organizations::Groups::TransferService.new(
          group: group,
          new_organization: organization,
          current_user: current_user
        ).execute
      end
    end
  end
end
