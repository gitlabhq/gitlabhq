# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GitlabSchema.types['CodequalityReportsComparerReportDegradation'], feature_category: :code_quality do
  specify { expect(described_class.graphql_name).to eq('CodequalityReportsComparerReportDegradation') }

  it 'has expected fields' do
    expected_fields = %i[description fingerprint severity file_path line web_url engine_name]

    expect(described_class).to have_graphql_fields(*expected_fields)
  end
end
