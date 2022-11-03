# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GitlabSchema.types['TimelineEventTagType'] do
  specify { expect(described_class.graphql_name).to eq('TimelineEventTagType') }

  specify { expect(described_class).to require_graphql_authorizations(:read_incident_management_timeline_event_tag) }

  it 'exposes the expected fields' do
    expected_fields = %i[
      id
      name
    ]

    expect(described_class).to have_graphql_fields(*expected_fields)
  end
end
