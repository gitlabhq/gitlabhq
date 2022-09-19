# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GitlabSchema.types['PushAccessLevel'] do
  subject { described_class }

  let(:fields) { %i[access_level access_level_description] }

  specify { is_expected.to require_graphql_authorizations(:read_protected_branch) }

  specify { is_expected.to have_graphql_fields(fields).at_least }
end
