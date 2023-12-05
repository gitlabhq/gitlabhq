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

      admin_bot = Users::Internal.admin_bot
      return unless admin_bot

      Gitlab::Auth::CurrentUserMode.bypass_session!(admin_bot.id) do
        deactivate_users(User.dormant, admin_bot)
        deactivate_users(User.with_no_activity, admin_bot)
      end
    end

    private

    def deactivate_users(scope, admin_bot)
      with_context(caller_id: self.class.name.to_s) do
        scope.each_batch do |batch|
          batch.each do |user|
            Users::DeactivateService.new(admin_bot).execute(user)
          end
        end
      end
    end
  end
end
