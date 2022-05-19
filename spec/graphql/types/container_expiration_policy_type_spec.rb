# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GitlabSchema.types['ContainerExpirationPolicy'] do
  specify { expect(described_class.graphql_name).to eq('ContainerExpirationPolicy') }

  specify { expect(described_class.description).to eq('A tag expiration policy designed to keep only the images that matter most') }

  specify { expect(described_class).to require_graphql_authorizations(:admin_container_image) }

  describe 'older_than field' do
    subject { described_class.fields['olderThan'] }

    it 'returns older_than enum' do
      is_expected.to have_graphql_type(Types::ContainerExpirationPolicyOlderThanEnum)
    end
  end

  describe 'keep n field' do
    subject { described_class.fields['keepN'] }

    it 'returns keep enum' do
      is_expected.to have_graphql_type(Types::ContainerExpirationPolicyKeepEnum)
    end
  end

  describe 'name_regex field' do
    subject { described_class.fields['nameRegex'] }

    it 'returns untrusted regexp type' do
      is_expected.to have_graphql_type(Types::UntrustedRegexp)
    end
  end

  describe 'name_regex_keep field' do
    subject { described_class.fields['nameRegexKeep'] }

    it 'returns untrusted regexp type' do
      is_expected.to have_graphql_type(Types::UntrustedRegexp)
    end
  end
end
