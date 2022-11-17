# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GitlabSchema.types['TimelineEventType'] do
  specify { expect(described_class.graphql_name).to eq('TimelineEventType') }

  specify { expect(described_class).to require_graphql_authorizations(:read_incident_management_timeline_event) }

  it 'exposes the expected fields' do
    expected_fields = %i[
      id
      author
      updated_by_user
      incident
      note
      note_html
      promoted_from_note
      editable
      action
      occurred_at
      created_at
      updated_at
      timeline_event_tags
    ]

    expect(described_class).to have_graphql_fields(*expected_fields)
  end
end
