# frozen_string_literal: true

require 'spec_helper'

describe GitlabSchema.types['AlertManagementAlert'] do
  it { expect(described_class.graphql_name).to eq('AlertManagementAlert') }

  it { expect(described_class).to require_graphql_authorizations(:read_alert_management_alerts) }

  it 'exposes the expected fields' do
    expected_fields = %i[
      iid
      title
      description
      severity
      status
      service
      monitoring_tool
      hosts
      started_at
      ended_at
      event_count
      details
      created_at
      updated_at
    ]

    expect(described_class).to have_graphql_fields(*expected_fields)
  end
end
