# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Types::Ci::TestReportSummaryType do
  specify { expect(described_class.graphql_name).to eq('TestReportSummary') }

  it 'contains attributes related to a pipeline test report summary' do
    expected_fields = %w[
      total test_suites
    ]

    expect(described_class).to have_graphql_fields(*expected_fields)
  end
end
