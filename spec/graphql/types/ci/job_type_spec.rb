# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Types::Ci::JobType do
  specify { expect(described_class.graphql_name).to eq('CiJob') }
  specify { expect(described_class).to require_graphql_authorizations(:read_commit_status) }

  it 'exposes the expected fields' do
    expected_fields = %i[
      allow_failure
      artifacts
      created_at
      detailedStatus
      duration
      finished_at
      id
      name
      needs
      pipeline
      queued_at
      scheduledAt
      schedulingType
      shortSha
      stage
      started_at
      status
    ]

    expect(described_class).to have_graphql_fields(*expected_fields)
  end
end
