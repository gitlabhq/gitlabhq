# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GitlabSchema.types['CiJobTokenScopeAllowlist'], feature_category: :secrets_management do
  specify { expect(described_class.graphql_name).to eq('CiJobTokenScopeAllowlist') }

  it 'exposes the expected fields' do
    expected_fields = %i[
      groups_allowlist
      projects_allowlist
    ]

    expect(described_class).to have_graphql_fields(*expected_fields)
  end

  describe 'max_page_size' do
    it 'matches the group link limit for groups_allowlist' do
      expect(described_class.fields['groupsAllowlist'].max_page_size)
        .to eq(::Ci::JobToken::GroupScopeLink::GROUP_LINK_LIMIT)
    end

    it 'matches the project link directional limit for projects_allowlist' do
      expect(described_class.fields['projectsAllowlist'].max_page_size)
        .to eq(::Ci::JobToken::ProjectScopeLink::PROJECT_LINK_DIRECTIONAL_LIMIT)
    end
  end
end
