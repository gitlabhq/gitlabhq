# frozen_string_literal: true

require 'rspec/core/sandbox'
require 'active_support/testing/time_helpers'

# rubocop:disable RSpec/MultipleMemoizedHelpers, Lint/EmptyBlock -- false positives for empty blocks and memoized helpers help with testing different data hash parameters
describe QA::Support::Formatters::TestMetricsFormatter do
  include QA::Support::Helpers::StubEnv
  include QA::Specs::Helpers::RSpec
  include ActiveSupport::Testing::TimeHelpers

  let(:url) { 'http://influxdb.net' }
  let(:token) { 'token' }
  let(:ci_timestamp) { '2021-02-23T20:58:41Z' }
  let(:ci_job_name) { 'test-job 1/5' }
  let(:ci_job_url) { 'url' }
  let(:ci_pipeline_url) { 'url' }
  let(:ci_pipeline_id) { '123' }
  let(:ci_job_id) { '321' }
  let(:run_type) { 'staging-full' }
  let(:smoke) { 'false' }
  let(:reliable) { 'false' }
  let(:blocking) { 'false' }
  let(:quarantined) { 'false' }
  let(:influx_client) { instance_double('InfluxDB2::Client', create_write_api: influx_write_api) }
  let(:influx_write_api) { instance_double('InfluxDB2::WriteApi', write: nil) }
  let(:file_path) { "./qa/specs/features/1_manage/subfolder/some_spec.rb" }
  let(:rerun_file_path) { "./qa/specs/features/1_manage/subfolder/some_spec.rb" }
  let(:ui_fabrication) { 0 }
  let(:api_fabrication) { 0 }
  let(:fabrication_resources) { {} }
  let(:testcase) { 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/1234' }
  let(:status) { :passed }

  let(:influx_client_args) do
    {
      bucket: 'e2e-test-stats',
      org: 'gitlab-qa',
      precision: InfluxDB2::WritePrecision::NANOSECOND
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
        reliable: reliable,
        blocking: blocking,
        quarantined: quarantined,
        job_name: 'test-job',
        merge_request: 'false',
        run_type: run_type,
        stage: 'manage',
        testcase: testcase
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
        failure_exception: ''
      }
    }
  end

  def run_spec(passed: true, &spec)
    spec ||= -> { it('spec', testcase: 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/1234') {} }
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
    allow(InfluxDB2::Client).to receive(:new).with(url, token, **influx_client_args) { influx_client }
    allow(QA::Tools::TestResourceDataProcessor).to receive(:resources) { fabrication_resources }
    allow_any_instance_of(RSpec::Core::Example::ExecutionResult).to receive(:run_time).and_return(0) # rubocop:disable RSpec/AnyInstanceOf
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

  context 'with influxdb variables configured' do
    let(:spec_name) { 'exports data' }
    let(:run_type) { ci_job_name.gsub(%r{ \d{1,2}/\d{1,2}}, '') }

    before do
      stub_env('QA_INFLUXDB_URL', url)
      stub_env('QA_INFLUXDB_TOKEN', token)
      stub_env('CI_PIPELINE_CREATED_AT', ci_timestamp)
      stub_env('CI_JOB_URL', ci_job_url)
      stub_env('CI_JOB_NAME', ci_job_name)
      stub_env('CI_PIPELINE_URL', ci_pipeline_url)
      stub_env('CI_PIPELINE_ID', ci_pipeline_id)
      stub_env('CI_JOB_ID', ci_job_id)
      stub_env('CI_MERGE_REQUEST_IID', nil)
      stub_env('TOP_UPSTREAM_MERGE_REQUEST_IID', nil)
      stub_env('QA_RUN_TYPE', run_type)
      stub_env('QA_EXPORT_TEST_METRICS', "true")
      stub_env('QA_RSPEC_RETRIED', "false")
    end

    context 'with reliable spec' do
      let(:reliable) { 'true' }

      it 'exports data to influxdb with correct reliable tag' do
        run_spec do
          it('spec', :reliable, testcase: 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/1234') {}
        end

        expect(influx_write_api).to have_received(:write).once
        expect(influx_write_api).to have_received(:write).with(data: [data])
      end
    end

    context 'with blocking spec' do
      let(:blocking) { 'true' }

      it 'exports data to influxdb with correct blocking tag' do
        run_spec do
          it('spec', :blocking, testcase: 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/1234') {}
        end

        expect(influx_write_api).to have_received(:write).once
        expect(influx_write_api).to have_received(:write).with(data: [data])
      end
    end

    context 'with product group tag' do
      it 'exports data to influxdb with correct reliable tag' do
        run_spec do
          it('spec', product_group: :import, testcase: 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/1234') {}
        end

        expect(influx_write_api).to have_received(:write).once
        expect(influx_write_api).to have_received(:write).with(
          data: [data.tap { |d| d[:tags][:product_group] = :import }]
        )
      end
    end

    context 'with smoke spec' do
      let(:smoke) { 'true' }

      it 'exports data to influxdb with correct smoke tag' do
        run_spec do
          it('spec', :smoke, testcase: 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/1234') {}
        end

        expect(influx_write_api).to have_received(:write).once
        expect(influx_write_api).to have_received(:write).with(data: [data])
      end
    end

    context 'with quarantined spec' do
      let(:quarantined) { 'true' }
      let(:status) { :pending }

      it 'exports data to influxdb with correct quarantine tag' do
        run_spec do
          it(
            'spec',
            :quarantine,
            skip: 'quarantined',
            testcase: 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/1234'
          ) {}
        end

        expect(influx_write_api).to have_received(:write).once
        expect(influx_write_api).to have_received(:write).with(data: [data])
      end
    end

    context 'with context quarantined spec' do
      let(:quarantined) { 'false' }

      it 'exports data to influxdb with correct quarantine tag' do
        run_spec do
          it(
            'spec',
            quarantine: { only: { job: 'praefect' } },
            testcase: 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/1234'
          ) {}
        end

        expect(influx_write_api).to have_received(:write).once
        expect(influx_write_api).to have_received(:write).with(data: [data])
      end
    end

    context 'with skipped spec' do
      let(:status) { :pending }

      it 'exports data with pending status' do
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

      it 'saves exception class' do
        run_spec(passed: false) do
          it('spec', testcase: 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/1234') { raise }
        end

        expect(influx_write_api).to have_received(:write).with(
          data: [data.tap { |d| d[:tags][:exception_class] = "RuntimeError" }]
        )
      end
    end

    context 'with retry in separate process' do
      before do
        stub_env('QA_DISABLE_RSPEC_RETRY', 'true')
      end

      context 'with initial run' do
        it 'skips failed spec' do
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

        it 'sets test as flaky' do
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

      it 'exports data to influxdb with correct run type' do
        run_spec

        expect(influx_write_api).to have_received(:write).once
        expect(influx_write_api).to have_received(:write).with(data: [data])
      end
    end

    context 'with staging sanity no admin' do
      let(:run_type) { 'staging-sanity-no-admin' }

      before do
        stub_env('CI_PROJECT_NAME', 'staging')
        stub_env('NO_ADMIN', 'true')
        stub_env('SMOKE_ONLY', 'true')
        stub_env('QA_RUN_TYPE', nil)
      end

      it 'exports data to influxdb with correct run type' do
        run_spec

        expect(influx_write_api).to have_received(:write).once
        expect(influx_write_api).to have_received(:write).with(data: [data])
      end
    end

    context 'with additional custom metrics' do
      it 'exports data to influxdb with additional metrics' do
        run_spec do
          it(
            'spec',
            custom_test_metrics: { tags: { custom_tag: "tag" }, fields: { custom_field: 1 } },
            testcase: 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/1234'
          ) {}
        end

        custom_data = data.merge({
          **data,
          tags: data[:tags].merge({ custom_tag: "tag" }),
          fields: data[:fields].merge({ custom_field: 1 })
        })

        expect(influx_write_api).to have_received(:write).once
        expect(influx_write_api).to have_received(:write).with(data: [custom_data])
      end
    end

    context 'with fabrication runtimes' do
      let(:api_fabrication) { 4 }
      let(:ui_fabrication) { 10 }

      it 'exports data to influxdb with fabrication times' do
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

        expect(influx_write_api).to have_received(:write).once
        expect(influx_write_api).to have_received(:write).with(data: [data])
      end
    end

    context 'with a shared example' do
      let(:file_path) { './qa/specs/features/shared_examples/merge_with_code_owner_shared_examples.rb' }
      let(:rerun_file_path) { './qa/specs/features/3_create/subfolder/another_spec.rb' }

      it 'exports data to influxdb with correct filename' do
        run_spec

        data[:tags][:file_path] = '/3_create/subfolder/another_spec.rb'
        data[:tags][:stage] = 'create'
        expect(influx_write_api).to have_received(:write).with(data: [data])
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
            merge_request: "false"
          },
          fields: {
            fabrication_time: 1,
            info: "with id '1'",
            job_url: ci_job_url,
            timestamp: Time.now.to_s
          }
        }
      end

      around do |example|
        freeze_time { example.run }
      end

      it 'exports fabrication stats data to influxdb' do
        run_spec

        expect(influx_write_api).to have_received(:write).with(data: [fabrication_data])
      end
    end

    context 'with persisting metrics' do
      before do
        stub_env('QA_EXPORT_TEST_METRICS', "false")
        stub_env('QA_SAVE_TEST_METRICS', "true")
        stub_env('CI_JOB_NAME_SLUG', "test-job")

        allow(File).to receive(:write)
      end

      it 'saves test metrics as json files' do
        run_spec

        expect(File).to have_received(:write).with("tmp/test-metrics-test-job-retry-false.json", [data].to_json)
      end
    end
  end
end
# rubocop:enable RSpec/MultipleMemoizedHelpers, Lint/EmptyBlock
