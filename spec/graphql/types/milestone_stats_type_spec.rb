# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GitlabSchema.types['MilestoneStats'] do
  it { expect(described_class).to require_graphql_authorizations(:read_milestone) }

  it 'has the expected fields' do
    expected_fields = %w[
      total_issues_count closed_issues_count
    ]

    expect(described_class).to include_graphql_fields(*expected_fields)
  end
end
