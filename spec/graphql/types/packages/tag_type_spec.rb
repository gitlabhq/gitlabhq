# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GitlabSchema.types['PackageTag'] do
  it { expect(described_class.graphql_name).to eq('PackageTag') }

  it 'includes all the package tag fields' do
    expected_fields = %w[
      id name created_at updated_at
    ]

    expect(described_class).to include_graphql_fields(*expected_fields)
  end
end
