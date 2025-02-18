# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GitlabSchema.types['BranchRule'], feature_category: :source_code_management do
  include GraphqlHelpers

  subject { described_class }

  let(:fields) do
    %i[
      name
      isDefault
      branch_protection
      matching_branches_count
      created_at
      updated_at
      squash_option
    ]
  end

  it { is_expected.to require_graphql_authorizations(:read_protected_branch) }

  it { is_expected.to have_graphql_fields(fields).at_least }
end
