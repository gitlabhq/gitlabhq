# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Types::Ci::PipelineType do
  specify { expect(described_class.graphql_name).to eq('Pipeline') }

  specify { expect(described_class).to expose_permissions_using(Types::PermissionTypes::Ci::Pipeline) }

  it 'contains attributes related to a pipeline' do
    expected_fields = %w[
      id iid sha before_sha complete status detailed_status config_source name
      duration queued_duration
      coverage created_at updated_at started_at finished_at committed_at
      stages user retryable cancelable jobs source_job job job_artifacts downstream
      upstream path project active user_permissions warnings commit commit_path uses_needs
      test_report_summary test_suite ref ref_path warning_messages merge_request_event_type
      name total_jobs triggered_by_path child source stuck
      latest merge_request ref_text failure_reason yaml_errors yaml_error_messages trigger
    ]

    if Gitlab.ee?
      expected_fields += %w[
        security_report_summary security_report_findings security_report_finding
        code_quality_reports dast_profile code_quality_report_summary compute_minutes
      ]
    end

    expect(described_class).to have_graphql_fields(*expected_fields)
  end
end
