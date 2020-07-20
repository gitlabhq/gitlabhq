# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GitlabSchema.types['ReleaseAssets'] do
  it { expect(described_class).to require_graphql_authorizations(:read_release) }

  it 'has the expected fields' do
    expected_fields = %w[
      count links sources
    ]

    expect(described_class).to include_graphql_fields(*expected_fields)
  end

  describe 'links field' do
    subject { described_class.fields['links'] }

    it { is_expected.to have_graphql_type(Types::ReleaseAssetLinkType.connection_type) }
  end

  describe 'sources field' do
    subject { described_class.fields['sources'] }

    it { is_expected.to have_graphql_type(Types::ReleaseSourceType.connection_type) }
  end
end
