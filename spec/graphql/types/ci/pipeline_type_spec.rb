# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Types::Ci::PipelineType, feature_category: :continuous_integration do
  include Ci::PipelineVariableHelpers

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
      pipeline_schedule
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
    fields_with_scopes = {
      'id' => %i[api read_api ai_workflows],
      'iid' => %i[api read_api ai_workflows],
      'sha' => %i[api read_api ai_workflows],
      'status' => %i[api read_api ai_workflows],
      'ref' => %i[api read_api ai_workflows],
      'name' => %i[api read_api ai_workflows],
      'createdAt' => %i[api read_api ai_workflows]
    }

    if Gitlab.ee?
      fields_with_scopes.merge!(
        'securityReportFindings' => %i[api read_api ai_workflows],
        'securityReportFinding' => %i[api read_api ai_workflows]
      )
    end

    fields_with_scopes.each do |field, scopes|
      it "includes the correct scopes for #{field}" do
        expect(described_class.fields[field].instance_variable_get(:@scopes)).to include(*scopes)
      end
    end
  end

  describe 'manual_variables' do
    let_it_be(:user) { create(:user) }
    let_it_be(:project) { create(:project, :repository) }
    let_it_be(:pipeline) { create(:ci_pipeline, project: project) }

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
      create_or_replace_pipeline_variables(pipeline, { key: 'KEY_1', value: 'VALUE_1' })
      project.add_role(user, user_access_level) # rubocop:disable RSpec/BeforeAllRoleAssignment -- need dynamic settings `user_access_level`
    end

    context 'when user has access to read variables' do
      let(:user_access_level) { :owner }

      it 'returns the manual variables' do
        expect(manual_variables.size).to eq(1)
        expect(manual_variables.first['key']).to eq('KEY_1')
        expect(manual_variables.first['value']).to eq('VALUE_1')
        expect(manual_variables.first.keys).to match_array(%w[id key value])
      end
    end

    context 'when user does not have access to read variables' do
      let(:user_access_level) { :developer }

      it 'returns the manual variables with nil values' do
        expect(manual_variables.size).to eq(1)
        expect(manual_variables.first['key']).to eq('KEY_1')
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

  describe 'retryable' do
    let_it_be(:user) { create(:user) }
    let_it_be(:project) { create(:project, :repository) }
    let_it_be(:pipeline) { create(:ci_pipeline, project: project) }

    let(:query) do
      %(
        {
          project(fullPath: "#{project.full_path}") {
            pipeline(iid: "#{pipeline.iid}") {
              retryable
            }
          }
        }
      )
    end

    let(:retryable) { data.dig('data', 'project', 'pipeline', 'retryable') }

    subject(:data) { GitlabSchema.execute(query, context: { current_user: user }).as_json }

    before_all do
      project.add_developer(user)
    end

    context 'when pipeline is archived' do
      before do
        pipeline.update_column(:created_at, 1.year.ago)
        stub_application_setting(archive_builds_in_seconds: 3600)
      end

      it 'returns false without querying builds' do
        expect(::Ci::Build).not_to receive(:retryable_pipeline_keys)
        expect(retryable).to eq(false)
      end
    end

    context 'when pipeline has no failed or canceled jobs' do
      before do
        create(:ci_build, :success, pipeline: pipeline)
      end

      it 'returns false' do
        expect(retryable).to eq(false)
      end
    end

    context 'when pipeline has failed jobs' do
      before do
        create(:ci_build, :failed, pipeline: pipeline)
      end

      it 'returns true' do
        expect(retryable).to eq(true)
      end
    end

    context 'when pipeline has canceled jobs' do
      before do
        create(:ci_build, :canceled, pipeline: pipeline)
      end

      it 'returns true' do
        expect(retryable).to eq(true)
      end
    end

    context 'when querying retryable across multiple pipelines' do
      let_it_be(:second_user) { create(:user) }

      let(:multi_pipeline_query) do
        %(
          {
            project(fullPath: "#{project.full_path}") {
              pipelines {
                nodes {
                  retryable
                }
              }
            }
          }
        )
      end

      before_all do
        project.add_developer(second_user)
      end

      it 'does not issue N+1 queries' do
        pipeline_2 = create(:ci_pipeline, project: project)
        create(:ci_build, :failed, pipeline: pipeline)
        create(:ci_build, :failed, pipeline: pipeline_2)

        control = ActiveRecord::QueryRecorder.new do
          GitlabSchema.execute(multi_pipeline_query, context: { current_user: user })
        end

        pipeline_3 = create(:ci_pipeline, project: project)
        create(:ci_build, :failed, pipeline: pipeline_3)

        expect do
          GitlabSchema.execute(multi_pipeline_query, context: { current_user: second_user })
        end.not_to exceed_query_limit(control)
      end
    end
  end

  describe 'pipeline_schedule' do
    let_it_be(:user) { create(:user) }
    let_it_be(:project) { create(:project, :repository, public_builds: false) }
    let_it_be(:schedule) { create(:ci_pipeline_schedule, project: project) }
    let_it_be(:pipeline) { create(:ci_pipeline, project: project, pipeline_schedule: schedule) }

    let(:query) do
      %(
        {
          project(fullPath: "#{project.full_path}") {
            pipeline(iid: "#{pipeline.iid}") {
              pipelineSchedule {
                id
              }
            }
          }
        }
      )
    end

    let(:pipeline_schedule) { data.dig('data', 'project', 'pipeline', 'pipelineSchedule') }

    subject(:data) { GitlabSchema.execute(query, context: { current_user: user }).as_json }

    before do
      project.add_role(user, user_access_level) # rubocop:disable RSpec/BeforeAllRoleAssignment -- need dynamic settings `user_access_level`
    end

    context 'when the pipeline was triggered by a schedule' do
      context 'when the user has permission to read the pipeline schedule' do
        let(:user_access_level) { :owner }

        it 'returns the pipeline schedule' do
          expect(pipeline_schedule).not_to be_nil
          expect(pipeline_schedule['id']).to eq(schedule.to_global_id.to_s)
        end
      end

      context 'when the user does not have permission to read the pipeline schedule' do
        let(:user_access_level) { :guest }

        it 'returns nil' do
          expect(pipeline_schedule).to be_nil
        end
      end
    end

    context 'when the pipeline was not triggered by a schedule' do
      let_it_be(:pipeline) { create(:ci_pipeline, project: project) }
      let(:user_access_level) { :developer }

      it 'returns nil' do
        expect(pipeline_schedule).to be_nil
      end
    end
  end

  describe 'stuck' do
    let_it_be(:user) { create(:user) }
    let_it_be(:project) { create(:project, :repository) }
    let_it_be(:pipeline) { create(:ci_pipeline, project: project) }

    let(:query) do
      %(
        {
          project(fullPath: "#{project.full_path}") {
            pipeline(iid: "#{pipeline.iid}") {
              stuck
            }
          }
        }
      )
    end

    let(:stuck) { data.dig('data', 'project', 'pipeline', 'stuck') }

    subject(:data) { GitlabSchema.execute(query, context: { current_user: user }).as_json }

    before_all do
      project.add_developer(user)
    end

    context 'when pipeline has no pending jobs' do
      before do
        create(:ci_build, :running, pipeline: pipeline)
      end

      it 'returns false' do
        expect(stuck).to eq(false)
      end
    end

    context 'when pipeline has a pending job and no runners are available' do
      before do
        create(:ci_build, :pending, pipeline: pipeline)
      end

      it 'returns true' do
        expect(stuck).to eq(true)
      end
    end

    context 'when project has a matching online runner' do
      let_it_be(:runner) { create(:ci_runner, :project, projects: [project], contacted_at: 1.second.ago) }

      before do
        create(:ci_build, :pending, pipeline: pipeline)
      end

      it 'returns false' do
        expect(stuck).to eq(false)
      end
    end

    context 'when project has a runner but it does not match the build tags' do
      let_it_be(:runner) do
        create(:ci_runner, :project, projects: [project], contacted_at: 1.second.ago, tag_list: ['windows'])
      end

      before do
        create(:ci_build, :pending, pipeline: pipeline, tag_list: ['linux'])
      end

      it 'returns true' do
        expect(stuck).to eq(true)
      end
    end

    context 'when multiple pipelines are queried' do
      let_it_be(:pipeline2) { create(:ci_pipeline, project: project) }

      let(:query) do
        %(
          {
            project(fullPath: "#{project.full_path}") {
              pipeline1: pipeline(iid: "#{pipeline.iid}") { stuck }
              pipeline2: pipeline(iid: "#{pipeline2.iid}") { stuck }
            }
          }
        )
      end

      before do
        create(:ci_build, :pending, pipeline: pipeline)
        create(:ci_build, :pending, pipeline: pipeline2)
      end

      it 'does not scale queries with the number of pipelines' do
        baseline = ActiveRecord::QueryRecorder.new do
          GitlabSchema.execute(query, context: { current_user: user }).as_json
        end

        pipeline3 = create(:ci_pipeline, project: project)
        create(:ci_build, :pending, pipeline: pipeline3)

        three_pipeline_query = %(
          {
            project(fullPath: "#{project.full_path}") {
              pipeline1: pipeline(iid: "#{pipeline.iid}") { stuck }
              pipeline2: pipeline(iid: "#{pipeline2.iid}") { stuck }
              pipeline3: pipeline(iid: "#{pipeline3.iid}") { stuck }
            }
          }
        )

        expect { GitlabSchema.execute(three_pipeline_query, context: { current_user: user }).as_json }
          .not_to exceed_query_limit(baseline)
      end

      context 'when builds have persisted tags and a matching online runner' do
        let_it_be(:runner) do
          create(:ci_runner, :project, projects: [project], contacted_at: 1.second.ago,
            run_untagged: true)
        end

        it 'does not issue extra queries per build when loading tags' do
          create(:ci_build, :pending, pipeline: pipeline)
          create(:ci_build, :pending, pipeline: pipeline2)

          baseline = ActiveRecord::QueryRecorder.new do
            GitlabSchema.execute(query, context: { current_user: user }).as_json
          end

          Gitlab::SafeRequestStore.clear!
          Ci::ApplicationRecord.connection.clear_query_cache
          BatchLoader::Executor.clear_current

          2.times { create(:ci_build, :pending, pipeline: pipeline) }
          2.times { create(:ci_build, :pending, pipeline: pipeline2) }

          expect { GitlabSchema.execute(query, context: { current_user: user }).as_json }
            .not_to exceed_query_limit(baseline).with_threshold(4)
        end
      end
    end
  end
end
