# frozen_string_literal: true

module Import
  module UserMapping
    class ProjectBotBypassAuthorizer
      def initialize(group, assignee_user, reassigned_by_user)
        @group = group.root_ancestor
        @assignee_user = assignee_user
        @reassigned_by_user = reassigned_by_user
      end

      def allowed?
        return false if Feature.disabled?(:user_mapping_service_account_and_bots, reassigned_by_user)
        return false unless reassigned_by_user.can?(:admin_namespace, group)
        return false unless assignee_user&.project_bot?

        bot_root_namespace_id = assignee_user.bot_namespace&.root_ancestor&.id
        bot_root_namespace_id == group.id
      end

      private

      attr_reader :assignee_user, :group, :reassigned_by_user
    end
  end
end
