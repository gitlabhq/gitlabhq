# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GitlabSchema.types['MlCandidate'], feature_category: :mlops do
  specify { expect(described_class.description).to eq('Candidate for a model version in the model registry') }

  it 'includes all the package fields' do
    expected_fields = %w[id name created_at _links]

    expect(described_class).to include_graphql_fields(*expected_fields)
  end
end
