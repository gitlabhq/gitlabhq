# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GitlabSchema.types['IssueStatusCountsType'] do
  specify { expect(described_class.graphql_name).to eq('IssueStatusCountsType') }

  it 'exposes the expected fields' do
    expected_fields = %i[
      all
      opened
      closed
    ]

    expect(described_class).to have_graphql_fields(*expected_fields)
  end
end
