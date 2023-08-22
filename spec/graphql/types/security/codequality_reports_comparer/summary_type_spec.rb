# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GitlabSchema.types['CodequalityReportsComparerReportSummary'], feature_category: :code_quality do
  specify { expect(described_class.graphql_name).to eq('CodequalityReportsComparerReportSummary') }

  it 'has expected fields' do
    expected_fields = %i[total resolved errored]

    expect(described_class).to have_graphql_fields(*expected_fields)
  end
end
