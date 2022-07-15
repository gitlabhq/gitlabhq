# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Types::Ci::JobType do
  specify { expect(described_class.graphql_name).to eq('CiJob') }
  specify { expect(described_class).to expose_permissions_using(Types::PermissionTypes::Ci::Job) }

  it 'exposes the expected fields' do
    expected_fields = %i[
      active
      allow_failure
      artifacts
      cancelable
      commitPath
      coverage
      created_at
      created_by_tag
      detailedStatus
      duration
      downstreamPipeline
      finished_at
      id
      kind
      manual_job
      manual_variables
      name
      needs
      pipeline
      playable
      previousStageJobsOrNeeds
      queued_at
      queued_duration
      refName
      refPath
      retryable
      retried
      scheduledAt
      schedulingType
      shortSha
      stage
      started_at
      status
      stuck
      tags
      triggered
      userPermissions
    ]

    expect(described_class).to have_graphql_fields(*expected_fields)
  end
end
