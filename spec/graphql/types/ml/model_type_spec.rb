# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GitlabSchema.types['MlModel'], feature_category: :mlops do
  specify { expect(described_class.description).to eq('Machine learning model in the model registry') }

  it 'includes all the package fields' do
    expected_fields = %w[id name versions candidates version_count _links created_at latest_version]

    expect(described_class).to include_graphql_fields(*expected_fields)
  end
end
