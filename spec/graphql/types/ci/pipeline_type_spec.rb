# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Types::Ci::PipelineType, feature_category: :continuous_integration do
  specify { expect(described_class.graphql_name).to eq('Pipeline') }

  specify { expect(described_class.interfaces).to include(::Types::Ci::PipelineInterface) }

  specify { expect(described_class).to expose_permissions_using(Types::PermissionTypes::Ci::Pipeline) }

  it 'contains attributes related to a pipeline' do
    expected_fields = %w[
      id
      iid
      sha
      before_sha
      complete
      status
      detailed_status
      config_source
      name
      duration
      queued_duration
      coverage
      created_at
      updated_at
      started_at
      finished_at
      committed_at
      stages
      user
      retryable
      cancelable
      jobs
      source_job
      job
      job_artifacts
      downstream
      upstream
      path
      project
      active
      user_permissions
      warnings
      commit
      commit_path
      uses_needs
      test_report_summary
      test_suite
      type
      ref
      ref_path
      warning_messages
      error_messages
      merge_request_event_type
      name
      total_jobs
      failed_jobs_count
      triggered_by_path
      child
      source
      stuck
      latest
      merge_request
      ref_text
      failure_reason
      yaml_errors
      yaml_error_messages
      trigger
      manual_variables
      has_manual_actions
      has_scheduled_actions
    ]

    if Gitlab.ee?
      expected_fields += %w[
        security_report_summary
        security_report_findings
        security_report_finding
        enabled_security_scans
        enabled_partial_security_scans
        troubleshoot_job_with_ai
        code_quality_reports
        dast_profile
        code_quality_report_summary
        compute_minutes
      ]
    end

    expect(described_class).to have_graphql_fields(*expected_fields)
  end

  describe '.authorization_scopes' do
    it 'includes :ai_workflows' do
      expect(described_class.authorization_scopes).to include(:ai_workflows)
    end
  end

  describe 'field scopes' do
    {
      'id' => %i[api read_api ai_workflows],
      'name' => %i[api read_api ai_workflows],
      'createdAt' => %i[api read_api ai_workflows]
    }.each do |field, scopes|
      it "includes the correct scopes for #{field}" do
        expect(described_class.fields[field].instance_variable_get(:@scopes)).to include(*scopes)
      end
    end
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

  describe 'failed_jobs_count' do
    let_it_be(:user) { create(:user) }
    let_it_be(:project) { create(:project, :repository) }
    let_it_be(:pipeline) { create(:ci_pipeline, project: project) }
    let(:query) do
      %(
        {
          project(fullPath: "#{project.full_path}") {
            pipeline(iid: "#{pipeline.iid}") {
              failedJobsCount
            }
          }
        }
      )
    end

    let(:failed_jobs_count) { data.dig('data', 'project', 'pipeline', 'failedJobsCount') }

    subject(:data) { GitlabSchema.execute(query, context: { current_user: user }).as_json }

    before_all do
      project.add_developer(user)
    end

    context 'when pipeline has no failed jobs' do
      before do
        create(:ci_build, :success, pipeline: pipeline)
        create(:ci_bridge, :success, pipeline: pipeline)
      end

      it 'returns 0' do
        expect(failed_jobs_count).to eq(0)
      end
    end

    context 'when pipeline has failed jobs' do
      before do
        create(:ci_build, :failed, pipeline: pipeline)
        create(:ci_bridge, :failed, pipeline: pipeline)
        create(:generic_commit_status, :failed, pipeline: pipeline)
        create(:ci_build, :success, pipeline: pipeline)
      end

      it 'returns the count of failed jobs' do
        expect(failed_jobs_count).to eq(3)
      end
    end

    context 'when pipeline has more than COUNT_FAILED_JOBS_LIMIT failed jobs' do
      before do
        stub_const("#{Ci::Pipeline}::COUNT_FAILED_JOBS_LIMIT", 3)
        create_list(:ci_build, 3, :failed, pipeline: pipeline)
        create_list(:ci_bridge, 3, :failed, pipeline: pipeline)
      end

      it 'returns the limited count' do
        expect(failed_jobs_count).to eq(3)
      end
    end
  end
end
