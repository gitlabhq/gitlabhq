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
          batch.each(&:deactivate)
        end
      end
    end
  end
end
