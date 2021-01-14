# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GitlabSchema.types['PackageComposerDetails'] do
  it { expect(described_class.graphql_name).to eq('PackageComposerDetails') }

  it 'includes all the package fields' do
    expected_fields = %w[
      id name version created_at updated_at package_type tags project pipelines versions
    ]

    expect(described_class).to include_graphql_fields(*expected_fields)
  end

  it 'includes composer specific files' do
    expected_fields = %w[
      composer_metadatum
    ]

    expect(described_class).to include_graphql_fields(*expected_fields)
  end
end
