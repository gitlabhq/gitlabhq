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

  describe '#triggered' do
    subject { resolve_field(:triggered, build, current_user: user, object_type: described_class) }

    let_it_be(:project) { create(:project) }
    let_it_be(:user) { create(:user) }

    context 'when not triggered' do
      let_it_be(:pipeline) { create(:ci_empty_pipeline, project: project) }
      let_it_be(:build) { create(:ci_build, pipeline: pipeline, project: project, user: user) }

      it 'returns false' do
        expect(build.pipeline).to receive(:trigger_id).and_call_original
        is_expected.to be(false)
      end

      context 'when ff ci_read_trigger_from_ci_pipeline is disabled' do
        before do
          stub_feature_flags(ci_read_trigger_from_ci_pipeline: false)
        end

        it 'returns false' do
          expect(build).to receive(:trigger_request).and_call_original
          is_expected.to be(false)
        end
      end
    end

    context 'when triggered' do
      let_it_be(:trigger) { create(:ci_trigger, project: project) }
      let_it_be(:trigger_request) { create(:ci_trigger_request, trigger: trigger) }
      let_it_be(:pipeline) { create(:ci_empty_pipeline, trigger: trigger, project: project) }
      let_it_be(:build) do
        create(:ci_build, trigger_request: trigger_request, pipeline: pipeline, project: project, user: user)
      end

      it 'returns true' do
        expect(build.pipeline).to receive(:trigger_id).and_call_original
        is_expected.to be(true)
      end

      context 'when ff ci_read_trigger_from_ci_pipeline is disabled' do
        before do
          stub_feature_flags(ci_read_trigger_from_ci_pipeline: false)
        end

        it 'returns true' do
          expect(build).to receive(:trigger_request).and_call_original
          is_expected.to be(true)
        end
      end
    end
  end
end
