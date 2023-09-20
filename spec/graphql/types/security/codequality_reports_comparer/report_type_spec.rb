# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GitlabSchema.types['CodequalityReportsComparerReport'], feature_category: :code_quality do
  specify { expect(described_class.graphql_name).to eq('CodequalityReportsComparerReport') }

  it 'has expected fields' do
    expected_fields = %i[status new_errors resolved_errors existing_errors summary]

    expect(described_class).to have_graphql_fields(*expected_fields)
  end
end
