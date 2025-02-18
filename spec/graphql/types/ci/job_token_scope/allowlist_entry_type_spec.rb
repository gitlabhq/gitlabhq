# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GitlabSchema.types['CiJobTokenScopeAllowlistEntry'], feature_category: :secrets_management do
  specify { expect(described_class.graphql_name).to eq('CiJobTokenScopeAllowlistEntry') }

  it 'exposes the expected fields' do
    expected_fields = %i[
      source_project
      target
      direction
      default_permissions
      job_token_policies
      added_by
      created_at
      autopopulated
    ]

    expect(described_class).to have_graphql_fields(*expected_fields)
  end
end
