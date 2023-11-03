# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GitlabSchema.types['CodequalityReportsComparerStatus'], feature_category: :code_quality do
  specify { expect(described_class.graphql_name).to eq('CodequalityReportsComparerStatus') }

  it 'exposes all codequality report status values' do
    expect(described_class.values.keys).to contain_exactly('SUCCESS', 'FAILED', 'NOT_FOUND')
  end
end
