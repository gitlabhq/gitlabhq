# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GitlabSchema.types['HelmFileMetadata'] do
  it { expect(described_class.graphql_name).to eq('HelmFileMetadata') }

  it 'includes helm file metadatum fields' do
    expected_fields = %w[
      created_at updated_at channel metadata
    ]

    expect(described_class).to include_graphql_fields(*expected_fields)
  end
end
