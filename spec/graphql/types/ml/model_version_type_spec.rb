# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GitlabSchema.types['MlModelVersion'], feature_category: :mlops do
  specify { expect(described_class.description).to eq('Version of a machine learning model') }

  it 'includes all the package fields' do
    expected_fields = %w[id version created_at _links]

    expect(described_class).to include_graphql_fields(*expected_fields)
  end
end
