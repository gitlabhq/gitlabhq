# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GitlabSchema.types['BranchRule'] do
  include GraphqlHelpers

  subject { described_class }

  let(:fields) { %i[name created_at updated_at] }

  specify { is_expected.to have_graphql_name('BranchRule') }

  specify { is_expected.to require_graphql_authorizations(:read_protected_branch) }

  specify { is_expected.to have_graphql_description }

  specify { is_expected.to have_graphql_fields(fields) }

  describe 'graphql_fields' do
    subject do
      described_class.all_field_definitions
    end

    specify { is_expected.to all(have_graphql_description) }
  end
end
