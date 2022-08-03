# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GitlabSchema.types['TimeTrackingTimelogCategory'] do
  let(:fields) do
    %w[
      id
      name
      description
      color
      billable
      billing_rate
      created_at
      updated_at
    ]
  end

  it { expect(described_class.graphql_name).to eq('TimeTrackingTimelogCategory') }
  it { expect(described_class).to have_graphql_fields(fields) }
  it { expect(described_class).to require_graphql_authorizations(:read_timelog_category) }
end
