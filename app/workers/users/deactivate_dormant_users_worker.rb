# frozen_string_literal: true

module Users
  class DeactivateDormantUsersWorker # rubocop:disable Scalability/IdempotentWorker
    include ApplicationWorker

    data_consistency :always

    include CronjobQueue

    feature_category :seat_cost_management

    def perform
      return if Gitlab.com?

      return unless ::Gitlab::CurrentSettings.current_application_settings.deactivate_dormant_users

      deactivate_users(User.dormant)
      deactivate_users(User.with_no_activity)
    end

    private

    def deactivate_users(scope)
      with_context(caller_id: self.class.name.to_s) do
        scope.each_batch do |batch|
          batch.each do |user|
            process_user_deactivation(user)
          end
        end
      end
    end

    def process_user_deactivation(user)
      admin_bot = admin_bot_for_organization_id(user.organization_id)
      Gitlab::Auth::CurrentUserMode.bypass_session!(admin_bot.id) do
        Users::DeactivateService.new(admin_bot).execute(user)
      end
    end

    def admin_bot_for_organization_id(organization_id)
      @admin_bots ||= {}
      @admin_bots[organization_id] ||= Users::Internal.for_organization(organization_id).admin_bot
    end
  end
end
