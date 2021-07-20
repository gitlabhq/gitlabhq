# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Types::Ci::PipelineType do
  specify { expect(described_class.graphql_name).to eq('Pipeline') }

  specify { expect(described_class).to expose_permissions_using(Types::PermissionTypes::Ci::Pipeline) }

  it 'contains attributes related to a pipeline' do
    expected_fields = %w[
      id iid sha before_sha complete status detailed_status config_source
      duration queued_duration
      coverage created_at updated_at started_at finished_at committed_at
      stages user retryable cancelable jobs source_job job downstream
      upstream path project active user_permissions warnings commit_path uses_needs
      test_report_summary test_suite ref
    ]

    if Gitlab.ee?
      expected_fields += %w[security_report_summary security_report_findings code_quality_reports]
    end

    expect(described_class).to have_graphql_fields(*expected_fields)
  end
end
