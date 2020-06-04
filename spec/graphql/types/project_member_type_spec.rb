# frozen_string_literal: true

require 'spec_helper'

describe GitlabSchema.types['ProjectMember'] do
  specify { expect(described_class.graphql_name).to eq('ProjectMember') }

  it 'has the expected fields' do
    expected_fields = %w[id accessLevel user]

    expect(described_class).to have_graphql_fields(*expected_fields)
  end

  specify { expect(described_class).to require_graphql_authorizations(:read_project) }
end
