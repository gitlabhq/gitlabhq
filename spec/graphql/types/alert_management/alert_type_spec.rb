# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GitlabSchema.types['AlertManagementAlert'], feature_category: :incident_management do
  specify { expect(described_class.graphql_name).to eq('AlertManagementAlert') }

  specify { expect(described_class).to require_graphql_authorizations(:read_alert_management_alert) }

  specify { expect(described_class.interfaces).to include(Types::TodoableInterface) }

  it 'exposes the expected fields' do
    expected_fields = %i[
      id
      iid
      issueIid
      issue
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
      assignees
      notes
      discussions
      runbook
      todos
      details_url
      metrics_dashboard_url
      prometheus_alert
      environment
      web_url
      commenters
      name
    ]

    expect(described_class).to have_graphql_fields(*expected_fields)
  end
end
