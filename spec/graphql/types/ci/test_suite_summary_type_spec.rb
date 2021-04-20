# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Types::Ci::TestSuiteSummaryType do
  specify { expect(described_class.graphql_name).to eq('TestSuiteSummary') }

  it 'contains attributes related to a pipeline test report summary' do
    expected_fields = %w[
      name total_time total_count success_count failed_count skipped_count error_count suite_error build_ids
    ]

    expect(described_class).to have_graphql_fields(*expected_fields)
  end
end
