# frozen_string_literal: true

require 'rspec/core/sandbox'
require 'active_support/testing/time_helpers'
require 'pathname'

# rubocop:disable RSpec/MultipleMemoizedHelpers, Lint/EmptyBlock -- false positives for empty blocks and memoized helpers help with testing different data hash parameters
describe QA::Support::Formatters::TestMetricsFormatter do
  include QA::Support::Helpers::StubEnv
  include QA::Specs::Helpers::RSpec
  include ActiveSupport::Testing::TimeHelpers

  # some specs are calculating spec location line number
  # keep this definition on top of the spec file so any change doesn't require test updates
  let(:default_spec_proc) do
    -> { it('spec', testcase: 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/1234') {} }
  end

  let(:metrics_gcs_project_id) { 'metrics-gcs-project' }
  let(:metrics_gcs_creds) { 'metrics-gcs-creds' }
  let(:metrics_gcs_bucket_name) { 'metrics-gcs-bucket' }
  let(:gcs_client_options) { { force: true, content_type: 'application/json' } }
  let(:gcs_client) { double("Fog::Google::StorageJSON::Real", put_object: nil) } # rubocop:disable RSpec/VerifiedDoubles -- instance_double complains put_object is not implemented but it is
  let(:ci_timestamp) { '2021-02-23T20:58:41Z' }
  let(:ci_job_name) { 'test-job 1/5' }
  let(:ci_job_url) { 'job-url' }
  let(:ci_job_status) { 'success' }
  let(:ci_pipeline_url) { 'pipeline-url' }
  let(:ci_pipeline_id) { '123' }
  let(:ci_job_id) { '321' }
  let(:branch) { 'master' }
  let(:run_type) { 'staging-full' }
  let(:smoke) { 'false' }
  let(:quarantined) { 'false' }
  let(:file_path) { "./qa/specs/features/1_manage/subfolder/some_spec.rb" }
  let(:rerun_file_path) { "./qa/specs/features/1_manage/subfolder/some_spec.rb" }
  let(:ui_fabrication) { 0 }
  let(:api_fabrication) { 0 }
  let(:fabrication_resources) { {} }
  let(:testcase) { 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/1234' }
  let(:status) { :passed }
  let(:retry_failed_specs) { false }
  let(:method_call_data) { {} }

  let(:data) do
    {
      name: 'test-stats',
      time: DateTime.strptime(ci_timestamp).to_time,
      tags: {
        name: 'stats export spec',
        file_path: file_path.gsub('./qa/specs/features', ''),
        status: status,
        smoke: smoke,
        quarantined: quarantined,
        job_name: 'test-job',
        merge_request: 'false',
        run_type: run_type,
        stage: 'manage',
        testcase: testcase,
        branch: branch
      },
      fields: {
        id: './spec/support/formatters/test_metrics_formatter_spec.rb[1:1]',
        run_time: 0,
        api_fabrication: api_fabrication * 1000,
        ui_fabrication: ui_fabrication * 1000,
        total_fabrication: (api_fabrication + ui_fabrication) * 1000,
        job_url: ci_job_url,
        job_status: ci_job_status,
        pipeline_url: ci_pipeline_url,
        pipeline_id: ci_pipeline_id,
        job_id: ci_job_id,
        failure_exception: '',
        location: %r{./#{Pathname.new(__FILE__).relative_path_from(Dir.pwd)}:\d+}
      }
    }
  end

  def run_spec(passed: true, &spec)
    spec ||= default_spec_proc
    method = passed ? :describe_successfully : :describe_unsuccessfully

    send(method, 'stats export', &spec).tap do |example_group|
      example_group.examples.each do |ex|
        ex.metadata[:file_path] = file_path
        ex.metadata[:rerun_file_path] = rerun_file_path
      end
    end
    send_stop_notification
  end

  around do |example|
    RSpec::Core::Sandbox.sandboxed do |config|
      config.formatter = described_class
      config.before(:context) { RSpec.current_example = nil }

      example.run
    end
  end

  before do
    allow(::Gitlab::QA::Runtime::Env).to receive(:retry_failed_specs?).and_return(retry_failed_specs)
    allow(Fog::Google::Storage).to receive(:new)
                                     .with(google_project: metrics_gcs_project_id,
                                       google_json_key_string: metrics_gcs_creds)
                                     .and_return(gcs_client)
    allow(QA::Tools::TestResourceDataProcessor).to receive(:resources) { fabrication_resources }
    allow(QA::Support::CodeRuntimeTracker).to receive(:method_call_data) { method_call_data }
    allow_any_instance_of(RSpec::Core::Example::ExecutionResult).to receive(:run_time).and_return(0) # rubocop:disable RSpec/AnyInstanceOf -- simplifies mocking runtime

    stub_env('QA_RUN_TYPE', run_type)
    stub_env('QA_METRICS_GCS_CREDS', metrics_gcs_creds)
    stub_env('GLCI_EXPORT_TEST_METRICS', "false")
  end

  context 'without GCS variables configured' do
    it 'skips export without gcs creds' do
      stub_env('QA_METRICS_GCS_CREDS', nil)

      run_spec

      expect(gcs_client).not_to have_received(:put_object)
    end

    it 'skips export without gcs project id' do
      stub_env('QA_METRICS_GCS_PROJECT_ID', nil)

      run_spec

      expect(gcs_client).not_to have_received(:put_object)
    end

    it 'skips export without gcs bucket name' do
      stub_env('QA_METRICS_GCS_BUCKET_NAME', nil)

      run_spec

      expect(gcs_client).not_to have_received(:put_object)
    end
  end

  context 'with variables configured' do
    let(:spec_name) { 'exports data' }
    let(:run_type) { ci_job_name.gsub(%r{ \d{1,2}/\d{1,2}}, '') }

    before do
      stub_env('CI_PIPELINE_CREATED_AT', ci_timestamp)
      stub_env('CI_JOB_URL', ci_job_url)
      stub_env('CI_JOB_NAME', ci_job_name)
      stub_env('CI_JOB_STATUS', ci_job_status)
      stub_env('CI_PIPELINE_URL', ci_pipeline_url)
      stub_env('CI_PIPELINE_ID', ci_pipeline_id)
      stub_env('CI_JOB_ID', ci_job_id)
      stub_env('CI_MERGE_REQUEST_IID', nil)
      stub_env('CI_COMMIT_REF_NAME', branch)
      stub_env('TOP_UPSTREAM_MERGE_REQUEST_IID', nil)
      stub_env('QA_RSPEC_RETRIED', "false")
      stub_env('GLCI_EXPORT_TEST_METRICS', "true")
    end

    context "with metrics upload to gcs" do
      let(:fabrication_resources) do
        {
          'QA::Resource::Project' => [{
            info: "with id '1'",
            api_path: '/project',
            fabrication_method: :api,
            fabrication_time: 1,
            http_method: :post,
            timestamp: Time.now.to_s
          }]
        }
      end

      let(:test_data) do
        data.tap { |d| d[:fields][:location] = "./#{Pathname.new(__FILE__).relative_path_from(Dir.pwd)}:16" }
      end

      let(:fabrication_data) do
        {
          name: 'fabrication-stats',
          time: DateTime.strptime(ci_timestamp).to_time,
          tags: {
            resource: 'QA::Resource::Project',
            fabrication_method: :api,
            http_method: :post,
            run_type: run_type,
            merge_request: "false",
            branch: branch
          },
          fields: {
            fabrication_time: 1,
            info: "with id '1'",
            job_url: ci_job_url,
            pipeline_url: ci_pipeline_url,
            timestamp: Time.now.to_s
          }
        }
      end

      before do
        stub_env('QA_METRICS_GCS_PROJECT_ID', metrics_gcs_project_id)
        stub_env('QA_METRICS_GCS_CREDS', metrics_gcs_creds)
        stub_env('QA_METRICS_GCS_BUCKET_NAME', metrics_gcs_bucket_name)
      end

      around do |example|
        freeze_time { example.run }
      end

      it "creates correct json files and uploads metrics to gcs" do
        run_spec

        expect(gcs_client).to have_received(:put_object).with(
          metrics_gcs_bucket_name,
          /test-metrics-\S+\.json/,
          [test_data].to_json,
          **gcs_client_options
        )
        expect(gcs_client).to have_received(:put_object).with(
          metrics_gcs_bucket_name,
          /fabrication-metrics-\S+\.json/,
          [fabrication_data].to_json,
          **gcs_client_options
        )
      end
    end
  end
end
# rubocop:enable RSpec/MultipleMemoizedHelpers, Lint/EmptyBlock
