# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GitlabSchema.types['ReleaseLinks'] do
  it { expect(described_class).to require_graphql_authorizations(:download_code) }

  it 'has the expected fields' do
    expected_fields = %w[
      selfUrl
      openedMergeRequestsUrl
      mergedMergeRequestsUrl
      closedMergeRequestsUrl
      openedIssuesUrl
      closedIssuesUrl
      editUrl
    ]

    expect(described_class).to include_graphql_fields(*expected_fields)
  end
end
