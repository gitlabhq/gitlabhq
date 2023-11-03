# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GitlabSchema.types['CodequalityReportsComparer'], feature_category: :code_quality do
  specify { expect(described_class.graphql_name).to eq('CodequalityReportsComparer') }

  it 'has expected fields' do
    expect(described_class).to have_graphql_fields(:status, :report)
  end
end
