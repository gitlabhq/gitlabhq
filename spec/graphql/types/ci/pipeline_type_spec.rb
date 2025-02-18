# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Types::Ci::PipelineType, feature_category: :continuous_integration do
  specify { expect(described_class.graphql_name).to eq('Pipeline') }

  specify { expect(described_class).to expose_permissions_using(Types::PermissionTypes::Ci::Pipeline) }

  it 'contains attributes related to a pipeline' do
    expected_fields = %w[
      id iid sha before_sha complete status detailed_status config_source name
      duration queued_duration
      coverage created_at updated_at started_at finished_at committed_at
      stages user retryable cancelable jobs source_job job job_artifacts downstream
      upstream path project active user_permissions warnings commit commit_path uses_needs
      test_report_summary test_suite type ref ref_path warning_messages error_messages merge_request_event_type
      name total_jobs triggered_by_path child source stuck
      latest merge_request ref_text failure_reason yaml_errors yaml_error_messages trigger manual_variables
    ]

    if Gitlab.ee?
      expected_fields += %w[
        security_report_summary security_report_findings security_report_finding troubleshoot_job_with_ai
        code_quality_reports dast_profile code_quality_report_summary compute_minutes
      ]
    end

    expect(described_class).to have_graphql_fields(*expected_fields)
  end

  describe 'manual_variables' do
    let_it_be(:user) { create(:user) }
    let_it_be(:project) { create(:project, :repository) }
    let_it_be(:pipeline) { create(:ci_pipeline, project: project) }
    let_it_be(:variable) { create(:ci_pipeline_variable, pipeline: pipeline, key: 'KEY_1', value: 'VALUE_1') }
    let(:query) do
      %(
        {
          project(fullPath: "#{project.full_path}") {
            id
            pipeline(iid: "#{pipeline.iid}") {
              id
              iid
              startedAt
              manualVariables {
                nodes {
                  id
                  key
                  value
                }
              }
            }
          }
        }
      )
    end

    let(:manual_variables) { data.dig('data', 'project', 'pipeline', 'manualVariables', 'nodes') }

    subject(:data) { GitlabSchema.execute(query, context: { current_user: user }).as_json }

    before do
      project.add_role(user, user_access_level) # rubocop:disable RSpec/BeforeAllRoleAssignment -- need dynamic settings `user_access_level`
    end

    context 'when user has access to read variables' do
      let(:user_access_level) { :owner }

      it 'returns the manual variables' do
        expect(manual_variables.size).to eq(1)
        expect(manual_variables.first['key']).to eq(variable.key)
        expect(manual_variables.first['value']).to eq(variable.value)
        expect(manual_variables.first.keys).to match_array(%w[id key value])
      end
    end

    context 'when user does not have access to read variables' do
      let(:user_access_level) { :developer }

      it 'returns the manual variables with nil values' do
        expect(manual_variables.size).to eq(1)
        expect(manual_variables.first['key']).to eq(variable.key)
        expect(manual_variables.first['value']).to eq(nil)
        expect(manual_variables.first.keys).to match_array(%w[id key value])
      end
    end
  end
end
