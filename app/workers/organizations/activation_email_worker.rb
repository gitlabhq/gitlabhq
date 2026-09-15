# frozen_string_literal: true

module Organizations
  class ActivationEmailWorker
    include Gitlab::EventStore::Subscriber

    data_consistency :sticky
    idempotent!

    feature_category :organization
    urgency :low

    defer_on_database_health_signal :gitlab_main, [:organizations], 1.minute

    def handle_event(event)
      organization = Organizations::Organization.find_by_id(event.event_data[:organization_id])
      return unless organization

      user_id = organization.state_metadata['confirmed_by_user_id']
      return unless user_id

      user = User.find_by_id(user_id)
      # Organizations confirmed by an internal bot (see Organizations::ConfirmWorker)
      # have no human recipient to notify.
      return unless user&.human?

      Notify.organization_activated_email(organization.id, user.id).deliver_later
    end
  end
end
