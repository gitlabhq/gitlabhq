# frozen_string_literal: true

module Organizations
  # Published when an organization transitions from `confirmed` to `active`.
  class ActivatedEvent < Gitlab::EventStore::CloudEvent
    event_category :organizations
    event_type :activated

    def self.build(organization:)
      build_cloud_event(
        source: "organizations/#{organization.id}",
        subject: "organizations/#{organization.id}",
        organization: organization,
        event_data: { organization_id: organization.id }
      )
    end

    def data_schema
      {
        'type' => 'object',
        'required' => %w[organization_id],
        'properties' => {
          'organization_id' => { 'type' => 'integer' }
        },
        'additionalProperties' => false
      }
    end
  end
end
