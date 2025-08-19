# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Types::Ci::JobInterface, feature_category: :continuous_integration do
  it 'has the correct name' do
    expect(described_class.graphql_name).to eq('CiJobInterface')
  end

  it 'has the expected fields' do
    expected_fields = %w[
      active
      allow_failure
      artifacts
      browse_artifacts_path
      can_play_job
      cancelable
      commit_path
      coverage
      created_at
      created_by_tag
      detailed_status
      duration
      erased_at
      exit_code
      failure_message
      finished_at
      id
      kind
      manual_job
      name
      pipeline
      play_path
      playable
      project
      queued_at
      queued_duration
      ref_name
      ref_path
      retried
      retryable
      retry_path
      runner
      scheduled
      scheduled_at
      scheduling_type
      short_sha
      source
      stage
      started_at
      status
      stuck
      tags
      trace
      triggered
      user_permissions
      web_path
    ]

    expect(described_class.own_fields.size).to eq(expected_fields.size)
    expect(described_class).to include_graphql_fields(*expected_fields)
  end

  describe ".resolve_type" do
    let_it_be(:user) { create(:user) }
    let_it_be(:job) { create(:ci_build, project: create(:project, :public)) }

    subject { described_class.resolve_type(job, { current_user: user }) }

    it { is_expected.to eq Types::Ci::JobType }
  end
end
