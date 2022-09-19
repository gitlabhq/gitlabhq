# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GitlabSchema.types['BranchProtection'] do
  subject { described_class }

  let(:fields) { %i[merge_access_levels push_access_levels allow_force_push] }

  specify { is_expected.to require_graphql_authorizations(:read_protected_branch) }

  specify { is_expected.to have_graphql_fields(fields).at_least }
end
