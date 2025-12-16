# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GitlabSchema.types['AutocompletedUser'], feature_category: :team_planning do
  it { expect(described_class).to require_graphql_authorizations(:read_user) }

  describe '#composite_identity_enforced' do
    subject { described_class.fields['compositeIdentityEnforced'] }

    it 'returns the correct type' do
      is_expected.to have_graphql_type(GraphQL::Types::Boolean.to_non_null_type)
    end
  end

  describe '#merge_request_interaction' do
    subject { described_class.fields['mergeRequestInteraction'] }

    it 'returns the correct type' do
      is_expected.to have_graphql_type(Types::UserMergeRequestInteractionType)
    end

    it 'has the correct arguments' do
      expect(subject.arguments).to have_key('id')
    end
  end
end
