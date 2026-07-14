# frozen_string_literal: true

module Organizations
  class ConfirmWorker
    include Gitlab::EventStore::Subscriber

    data_consistency :sticky
    idempotent!

    feature_category :organization
    urgency :low

    defer_on_database_health_signal :gitlab_main, [:namespaces, :organizations], 1.minute

    def handle_event(event)
      operation = event.data[:operation]
      actor = event.data[:actor]

      return unless operation == Feature::OPERATION_ENABLED_ACTOR

      organization = find_organization_from_actor(actor)
      return unless organization
      return unless Feature.enabled?(:root_group_organization_confirm, organization)

      user = find_confirming_user(organization)
      return unless user

      Organizations::ConfirmService.new(user, { organization_id: organization.id }).execute
    end

    private

    def find_organization_from_actor(actor)
      return unless actor

      class_name, id = actor.rpartition(':').values_at(0, 2)
      return unless class_name == 'Organizations::Organization' && id.present?

      Organizations::Organization.find_by_id(id.to_i)
    end

    def find_confirming_user(organization)
      ::Users::Internal.in_organization(organization.id).admin_bot
    end
  end
end
