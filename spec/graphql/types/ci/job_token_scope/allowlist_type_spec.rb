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
end
