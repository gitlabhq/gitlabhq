# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Types::Ci::JobType, feature_category: :continuous_integration do
  include GraphqlHelpers

  specify { expect(described_class.graphql_name).to eq('CiJob') }
  specify { expect(described_class).to expose_permissions_using(Types::PermissionTypes::Ci::Job) }

  it 'exposes the expected fields' do
    expected_fields = %i[
      active
      allow_failure
      artifacts
      browse_artifacts_path
      cancelable
      commitPath
      coverage
      created_at
      created_by_tag
      detailedStatus
      duration
      downstreamPipeline
      erasedAt
      finished_at
      id
      kind
      manual_job
      manual_variables
      name
      needs
      pipeline
      playable
      previousStageJobs
      previousStageJobsOrNeeds
      project
      queued_at
      queued_duration
      refName
      refPath
      retryable
      retried
      runner
      runnerManager
      scheduledAt
      schedulingType
      shortSha
      source
      stage
      started_at
      status
      stuck
      tags
      triggered
      userPermissions
      webPath
      playPath
      canPlayJob
      scheduled
      trace
      failure_message
      exit_code
    ]

    expect(described_class).to have_graphql_fields(*expected_fields)
  end

  describe '#web_path' do
    subject { resolve_field(:web_path, build, current_user: user, object_type: described_class) }

    let(:project) { create(:project) }
    let(:user) { create(:user) }
    let(:build) { create(:ci_build, project: project, user: user) }

    it 'returns the web path of the job' do
      is_expected.to eq("/#{project.full_path}/-/jobs/#{build.id}")
    end
  end

  describe '#browse_artifacts_path' do
    subject { resolve_field(:browse_artifacts_path, build, current_user: user, object_type: described_class) }

    let_it_be(:project) { create(:project) }
    let(:user) { create(:user) }
    let(:build) { create(:ci_build, :artifacts, project: project, user: user) }

    it 'returns the path to browse the artifacts of the job' do
      is_expected.to eq("/#{project.full_path}/-/jobs/#{build.id}/artifacts/browse")
    end
  end
end
