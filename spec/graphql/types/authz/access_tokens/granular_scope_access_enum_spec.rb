# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Types::Authz::AccessTokens::GranularScopeAccessEnum, feature_category: :permissions do
  specify { expect(described_class.graphql_name).to eq('AccessTokenGranularScopeAccess') }

  it 'exposes the expected granular scope access' do
    expect(described_class.values).to match(
      'PERSONAL_PROJECTS' => have_attributes(
        value: 'personal_projects'
      ),
      'ALL_MEMBERSHIPS' => have_attributes(
        value: 'all_memberships'
      ),
      'SELECTED_MEMBERSHIPS' => have_attributes(
        value: 'selected_memberships'
      ),
      'USER' => have_attributes(
        value: 'user'
      ),
      'INSTANCE' => have_attributes(
        value: 'instance'
      )
    )
  end
end
