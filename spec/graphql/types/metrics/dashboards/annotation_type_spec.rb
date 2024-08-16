# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GitlabSchema.types['MetricsDashboardAnnotation'] do
  specify { expect(described_class.graphql_name).to eq('MetricsDashboardAnnotation') }

  it 'has the expected fields' do
    expected_fields = %w[
      description id panel_id starting_at ending_at
    ]

    expect(described_class).to have_graphql_fields(*expected_fields)
  end
end
