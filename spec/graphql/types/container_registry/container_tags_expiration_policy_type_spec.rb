# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GitlabSchema.types['ContainerTagsExpirationPolicy'], feature_category: :container_registry do
  specify { expect(described_class.graphql_name).to eq('ContainerTagsExpirationPolicy') }

  specify do
    expect(described_class.description)
      .to eq('A tag expiration policy using regex patterns to control which images to keep or expire.')
  end

  specify { expect(described_class).to require_graphql_authorizations(:read_container_image) }

  def fetch_authorizations(field_name)
    described_class.fields[field_name].instance_variable_get(:@authorize)
  end

  describe 'older_than field' do
    subject { described_class.fields['olderThan'] }

    it 'returns older_than type' do
      is_expected.to have_graphql_type(Types::ContainerExpirationPolicyOlderThanEnum)
    end

    it 'has valid authorization' do
      expect(fetch_authorizations('olderThan')).to include(:admin_container_image)
    end
  end

  describe 'keep n field' do
    subject { described_class.fields['keepN'] }

    it 'returns keep enum' do
      is_expected.to have_graphql_type(Types::ContainerExpirationPolicyKeepEnum)
    end

    it 'has valid authorization' do
      expect(fetch_authorizations('keepN')).to include(:admin_container_image)
    end
  end

  describe 'name_regex field' do
    subject { described_class.fields['nameRegex'] }

    it 'returns untrusted regexp type' do
      is_expected.to have_graphql_type(Types::UntrustedRegexp)
    end

    it 'has valid authorization' do
      expect(fetch_authorizations('nameRegex')).to include(:admin_container_image)
    end
  end

  describe 'name_regex_keep field' do
    subject { described_class.fields['nameRegexKeep'] }

    it 'returns untrusted regexp type' do
      is_expected.to have_graphql_type(Types::UntrustedRegexp)
    end

    it 'has valid authorization' do
      expect(fetch_authorizations('nameRegexKeep')).to include(:admin_container_image)
    end
  end

  describe 'next_run_at field' do
    subject { described_class.fields['nextRunAt'] }

    it 'returns time type' do
      is_expected.to have_graphql_type(Types::TimeType)
    end

    it 'has valid authorization' do
      expect(fetch_authorizations('nextRunAt')).not_to include(:admin_container_image)
    end
  end

  describe 'cadence field' do
    subject { described_class.fields['cadence'] }

    it 'returns cadence enum' do
      is_expected.to have_graphql_type(Types::ContainerExpirationPolicyCadenceEnum)
    end

    it 'has valid authorization' do
      expect(fetch_authorizations('cadence')).to include(:admin_container_image)
    end
  end

  describe 'enabled field' do
    subject { described_class.fields['enabled'] }

    it 'returns boolean type' do
      is_expected.to have_graphql_type(GraphQL::Types::Boolean.to_non_null_type)
    end

    it 'has valid authorization' do
      expect(fetch_authorizations('enabled')).not_to include(:admin_container_image)
    end
  end
end
