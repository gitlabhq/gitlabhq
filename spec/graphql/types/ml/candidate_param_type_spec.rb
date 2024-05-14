# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GitlabSchema.types['MlCandidateParam'], feature_category: :mlops do
  it 'has the expected fields' do
    expected_fields = %w[id name value]

    expect(described_class).to include_graphql_fields(*expected_fields)
  end
end
