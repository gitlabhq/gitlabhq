# frozen_string_literal: true

require 'spec_helper'

describe GitlabSchema.types['Board'] do
  specify { expect(described_class.graphql_name).to eq('Board') }

  specify { expect(described_class).to require_graphql_authorizations(:read_board) }

  it 'has specific fields' do
    expected_fields = %w[id name]

    expect(described_class).to include_graphql_fields(*expected_fields)
  end
end
