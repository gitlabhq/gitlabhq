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

  let(:url) { 'http://influxdb.net' }
  let(:token) { 'token' }
  let(:metrics_gcs_project_id) { 'metrics-gcs-project' }
  let(:metrics_gcs_creds) { 'metrics-gcs-creds' }
  let(:metrics_gcs_bucket_name) { 'metrics-gcs-bucket' }
  let(:gcs_client_options) { { force: true, content_type: 'application/json' } }
  let(:gcs_client) { double("Fog::Storage::GoogleJSON::Real", put_object: nil) } # rubocop:disable RSpec/VerifiedDoubles -- instance_double complains put_object is not implemented but it is
  let(:ci_timestamp) { '2021-02-23T20:58:41Z' }
  let(:ci_job_name) { 'test-job 1/5' }
  let(:ci_job_url) { 'job-url' }
  let(:ci_pipeline_url) { 'pipeline-url' }
  let(:ci_pipeline_id) { '123' }
  let(:ci_job_id) { '321' }
  let(:branch) { 'master' }
  let(:run_type) { 'staging-full' }
  let(:smoke) { 'false' }
  let(:quarantined) { 'false' }
  let(:failure_issue) { '' }
  let(:influx_client) { instance_double('InfluxDB2::Client', create_write_api: influx_write_api) }
  let(:influx_write_api) { instance_double('InfluxDB2::WriteApi', write: nil) }
  let(:file_path) { "./qa/specs/features/1_manage/subfolder/some_spec.rb" }
  let(:rerun_file_path) { "./qa/specs/features/1_manage/subfolder/some_spec.rb" }
  let(:ui_fabrication) { 0 }
  let(:api_fabrication) { 0 }
  let(:fabrication_resources) { {} }
  let(:testcase) { 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/1234' }
  let(:status) { :passed }
  let(:retry_failed_specs) { false }
  let(:method_call_data) { {} }

  let(:influx_client_args) do
    {
      bucket: 'e2e-test-stats',
      org: 'gitlab-qa',
      precision: InfluxDB2::WritePrecision::NANOSECOND,
      read_timeout: 10,
      open_timeout: 10
    }
  end

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
    allow(InfluxDB2::Client).to receive(:new).with(url, token, **influx_client_args) { influx_client }
    allow(Fog::Storage::Google).to receive(:new)
                                     .with(google_project: metrics_gcs_project_id,
                                       google_json_key_string: metrics_gcs_creds)
                                     .and_return(gcs_client)
    allow(QA::Tools::TestResourceDataProcessor).to receive(:resources) { fabrication_resources }
    allow(QA::Support::CodeRuntimeTracker).to receive(:method_call_data) { method_call_data }
    allow_any_instance_of(RSpec::Core::Example::ExecutionResult).to receive(:run_time).and_return(0) # rubocop:disable RSpec/AnyInstanceOf -- simplifies mocking runtime

    stub_env('QA_RUN_TYPE', run_type)
  end

  context 'without influxdb variables configured' do
    it 'skips export without influxdb url' do
      stub_env('QA_INFLUXDB_URL', nil)
      stub_env('QA_INFLUXDB_TOKEN', nil)

      run_spec

      expect(influx_client).not_to have_received(:create_write_api)
    end

    it 'skips export without influxdb token' do
      stub_env('QA_INFLUXDB_URL', url)
      stub_env('QA_INFLUXDB_TOKEN', nil)

      run_spec

      expect(influx_client).not_to have_received(:create_write_api)
    end
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

  context 'with influxdb variables configured' do
    let(:spec_name) { 'exports data' }
    let(:run_type) { ci_job_name.gsub(%r{ \d{1,2}/\d{1,2}}, '') }

    before do
      stub_env('QA_METRICS_GCS_CREDS', nil)
      stub_env('QA_INFLUXDB_URL', url)
      stub_env('QA_INFLUXDB_TOKEN', token)
      stub_env('CI_PIPELINE_CREATED_AT', ci_timestamp)
      stub_env('CI_JOB_URL', ci_job_url)
      stub_env('CI_JOB_NAME', ci_job_name)
      stub_env('CI_PIPELINE_URL', ci_pipeline_url)
      stub_env('CI_PIPELINE_ID', ci_pipeline_id)
      stub_env('CI_JOB_ID', ci_job_id)
      stub_env('CI_MERGE_REQUEST_IID', nil)
      stub_env('CI_COMMIT_REF_NAME', branch)
      stub_env('TOP_UPSTREAM_MERGE_REQUEST_IID', nil)
      stub_env('QA_EXPORT_TEST_METRICS', "true")
      stub_env('QA_RSPEC_RETRIED', "false")
      stub_env('QA_INFLUXDB_TIMEOUT', "10")
    end

    context 'with product group tag' do
      let(:expected_data) { data.tap { |d| d[:tags][:product_group] = :import } }

      it 'exports data with correct product group tag' do
        run_spec do
          it('spec', product_group: :import, testcase: 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/1234') {}
        end

        expect(influx_write_api).to have_received(:write).with(data: [expected_data])
      end
    end

    context 'with smoke spec' do
      let(:smoke) { 'true' }

      it 'exports data with correct smoke tag', :aggregate_failures do
        run_spec do
          it('spec', :smoke, testcase: 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/1234') {}
        end

        expect(influx_write_api).to have_received(:write).with(data: [data])
      end
    end

    context 'with quarantined spec' do
      let(:quarantined) { 'true' }
      let(:status) { :pending }
      let(:expected_data) { data.tap { |d| d[:fields][:failure_issue] = 'https://example.com/issue/1234' } }

      it 'exports data with correct quarantine tag', :aggregate_failures do
        run_spec do
          it(
            'spec',
            quarantine: {
              type: :stale,
              issue: 'https://example.com/issue/1234'
            },
            skip: 'quarantined',
            testcase: 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/1234'
          ) {}
        end

        expect(influx_write_api).to have_received(:write).with(data: [expected_data])
      end
    end

    context 'with context quarantined spec' do
      let(:quarantined) { 'false' }
      let(:expected_data) { data.tap { |d| d[:fields][:failure_issue] = 'https://example.com/issue/1234' } }

      it 'exports data with correct quarantine tag', :aggregate_failures do
        run_spec do
          it(
            'spec',
            quarantine: { only: { job: 'praefect' }, issue: 'https://example.com/issue/1234' },
            testcase: 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/1234'
          ) {}
        end

        expect(influx_write_api).to have_received(:write).with(data: [expected_data])
      end
    end

    context 'with skipped spec' do
      let(:status) { :pending }

      it 'exports data with pending status', :aggregate_failures do
        run_spec do
          it(
            'spec',
            skip: 'not compatible',
            testcase: 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/1234'
          ) {}
        end

        expect(influx_write_api).to have_received(:write).with(data: [data])
      end
    end

    context 'with failed spec' do
      let(:status) { :failed }
      let(:expected_data) { data.tap { |d| d[:tags][:exception_class] = "RuntimeError" } }

      it 'saves exception class', :aggregate_failures do
        run_spec(passed: false) do
          it('spec', testcase: 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/1234') { raise }
        end

        expect(influx_write_api).to have_received(:write).with(data: [expected_data])
      end
    end

    context 'with retry in separate process' do
      let(:retry_failed_specs) { true }

      context 'with initial run' do
        it 'skips failed spec', :aggregate_failures do
          run_spec(passed: false) do
            it('spec', testcase: 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/1234') { raise }
          end

          expect(influx_write_api).to have_received(:write).with(data: [])
        end
      end

      context 'with retry run' do
        let(:status) { :flaky }

        before do
          stub_env('QA_RSPEC_RETRIED', 'true')
        end

        it 'sets test as flaky', :aggregate_failures do
          run_spec do
            it('spec', testcase: 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/1234') {}
          end

          expect(influx_write_api).to have_received(:write).with(data: [data])
        end
      end
    end

    context 'with staging full run' do
      let(:run_type) { 'staging-full' }

      before do
        stub_env('CI_PROJECT_NAME', 'staging')
        stub_env('QA_RUN_TYPE', nil)
      end

      it 'exports data with correct run type', :aggregate_failures do
        run_spec

        expect(influx_write_api).to have_received(:write).with(data: [data])
      end
    end

    context 'with additional custom metrics' do
      it 'exports data additional metrics', :aggregate_failures do
        run_spec do
          it(
            'spec',
            custom_test_metrics: { tags: { custom_tag: "tag" }, fields: { custom_field: 1 } },
            testcase: 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/1234'
          ) {}
        end

        custom_data = data.merge({
          tags: data[:tags].merge({ custom_tag: "tag" }),
          fields: data[:fields].merge({ custom_field: 1 })
        })

        expect(influx_write_api).to have_received(:write).with(data: [custom_data])
      end
    end

    context 'with fabrication runtimes' do
      let(:api_fabrication) { 4 }
      let(:ui_fabrication) { 10 }

      it 'exports data with fabrication times', :aggregate_failures do
        run_spec do
          # Main logic tracks fabrication time in thread local variable and injects it as metadata from
          # global after hook defined in main spec_helper.
          #
          # Inject the values directly since we do not load e2e test spec_helper in unit tests
          it(
            'spec',
            api_fabrication: 4,
            browser_ui_fabrication: 10,
            testcase: 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/1234'
          ) {}
        end

        expect(influx_write_api).to have_received(:write).with(data: [data])
      end
    end

    context 'with a shared example' do
      let(:file_path) { './qa/specs/features/shared_examples/merge_with_code_owner_shared_examples.rb' }
      let(:rerun_file_path) { './qa/specs/features/3_create/subfolder/another_spec.rb' }
      let(:expected_data) do
        data.tap do |d|
          d[:tags][:file_path] = '/3_create/subfolder/another_spec.rb'
          d[:tags][:stage] = 'create'
        end
      end

      it 'exports data to influxdb with correct filename', :aggregate_failures do
        run_spec

        expect(influx_write_api).to have_received(:write).with(data: [expected_data])
      end
    end

    context 'with fabrication resources' do
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

      around do |example|
        freeze_time { example.run }
      end

      it 'exports fabrication data to influxdb and GCS', :aggregate_failures do
        run_spec

        expect(influx_write_api).to have_received(:write).with(data: [fabrication_data])
      end
    end

    context 'with persisting metrics' do
      let(:expected_data) do
        data.tap { |d| d[:fields][:location] = "./#{Pathname.new(__FILE__).relative_path_from(Dir.pwd)}:16" }
      end

      before do
        stub_env('QA_EXPORT_TEST_METRICS', "false")
        stub_env('QA_SAVE_TEST_METRICS', "true")
        stub_env('CI_JOB_NAME_SLUG', "test-job")

        allow(File).to receive(:write)
      end

      context 'without retry enabled' do
        let(:file) { 'tmp/test-metrics-test-job.json' }

        it 'saves test metrics as json files' do
          run_spec

          expect(File).to have_received(:write).with(file, [expected_data].to_json)
        end
      end

      context 'with retry enabled' do
        let(:retry_failed_specs) { true }
        let(:file) { 'tmp/test-metrics-test-job-retry-false.json' }

        it 'saves test metrics as json files' do
          run_spec

          expect(File).to have_received(:write).with(file, [expected_data].to_json)
        end
      end
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

    context "with code runtime metrics" do
      let(:time) { DateTime.strptime(ci_timestamp).to_time }

      let(:method_call_data) do
        {
          "has_element?" => [{ runtime: 1, filename: "file.rb", call_arg: "element_for_has" }],
          "click" => [{ runtime: 1, filename: "file.rb", call_arg: "element_for_click" }]
        }
      end

      let(:expected_fields) do
        { job_url: ci_job_url, pipeline_url: ci_pipeline_url, runtime: 1000, filename: "file.rb" }
      end

      let(:expected_tags) do
        { run_type: run_type, merge_request: "false", branch: branch }
      end

      it "exports code runtime metrics to influxdb" do
        run_spec

        expect(influx_write_api).to have_received(:write).with(data: [
          {
            name: "method-call-stats", time: time,
            tags: { method: "has_element?", call_arg: "element_for_has", **expected_tags },
            fields: expected_fields
          },
          {
            name: "method-call-stats", time: time,
            tags: { method: "click", call_arg: "element_for_click", **expected_tags },
            fields: expected_fields
          }
        ])
      end
    end
  end
end
# rubocop:enable RSpec/MultipleMemoizedHelpers, Lint/EmptyBlock
