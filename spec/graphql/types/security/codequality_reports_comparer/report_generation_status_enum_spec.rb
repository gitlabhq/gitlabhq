# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GitlabSchema.types['CodequalityReportsComparerReportGenerationStatus'], feature_category: :code_quality do
  specify { expect(described_class.graphql_name).to eq('CodequalityReportsComparerReportGenerationStatus') }

  it 'exposes all codequality report status values' do
    expect(described_class.values.keys).to contain_exactly('PARSED', 'PARSING', 'ERROR')
  end
end
