# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GitlabSchema.types['Board'] do
  specify { expect(described_class.graphql_name).to eq('Board') }

  specify { expect(described_class).to require_graphql_authorizations(:read_issue_board) }

  it 'has specific fields' do
    expected_fields = %w[
      id
      name
      hideBacklogList
      hideClosedList
      createdAt
      updatedAt
      lists
      webPath
      webUrl
    ]

    expect(described_class).to have_graphql_fields(*expected_fields).at_least
  end
end
