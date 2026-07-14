# frozen_string_literal: true

module Organizations
  class ActivateWorker
    include Gitlab::EventStore::Subscriber

    data_consistency :sticky
    idempotent!

    feature_category :organization
    urgency :low

    defer_on_database_health_signal :gitlab_main, [:organizations, :namespaces], 1.minute

    def handle_event(event)
      organization_id = event.data[:organization_id]

      organization = Organizations::Organization.find_by_id(organization_id)
      return unless organization

      user_id = organization.state_metadata['confirmed_by_user_id']
      return unless user_id

      user = User.find_by_id(user_id)
      return unless user

      Organizations::ActivateService.new(user, { organization_id: organization_id }).execute
    end
  end
end
