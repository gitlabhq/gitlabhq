# frozen_string_literal: true

require 'spec_helper'

describe GitlabSchema.types['MetricsDashboard'] do
  it { expect(described_class.graphql_name).to eq('MetricsDashboard') }

  it 'has the expected fields' do
    expected_fields = %w[
      path
    ]

    expect(described_class).to have_graphql_fields(*expected_fields)
  end
end
