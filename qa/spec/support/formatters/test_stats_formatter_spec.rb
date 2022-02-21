# frozen_string_literal: true

require 'rspec/core/sandbox'
require 'active_support/testing/time_helpers'

describe QA::Support::Formatters::TestStatsFormatter do
  include QA::Support::Helpers::StubEnv
  include QA::Specs::Helpers::RSpec
  include ActiveSupport::Testing::TimeHelpers

  let(:url) { "http://influxdb.net" }
  let(:token) { "token" }
  let(:ci_timestamp) { "2021-02-23T20:58:41Z" }
  let(:ci_job_name) { "test-job 1/5" }
  let(:ci_job_url) { "url" }
  let(:ci_pipeline_url) { "url" }
  let(:ci_pipeline_id) { "123" }
  let(:run_type) { 'staging-full' }
  let(:reliable) { 'false' }
  let(:quarantined) { 'false' }
  let(:influx_client) { instance_double('InfluxDB2::Client', create_write_api: influx_write_api) }
  let(:influx_write_api) { instance_double('InfluxDB2::WriteApi', write: nil) }
  let(:stage) { '1_manage' }
  let(:file_path) { "./qa/specs/features/#{stage}/subfolder/some_spec.rb" }
  let(:ui_fabrication) { 0 }
  let(:api_fabrication) { 0 }
  let(:fabrication_resources) { {} }

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
        status: :passed,
        reliable: reliable,
        quarantined: quarantined,
        retried: "false",
        job_name: "test-job",
        merge_request: "false",
        run_type: run_type,
        stage: stage.match(%r{\d{1,2}_(\w+)}).captures.first,
        testcase: 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/1234'
      },
      fields: {
        id: './spec/support/formatters/test_stats_formatter_spec.rb[1:1]',
        run_time: 0,
        api_fabrication: api_fabrication * 1000,
        ui_fabrication: ui_fabrication * 1000,
        total_fabrication: (api_fabrication + ui_fabrication) * 1000,
        retry_attempts: 0,
        job_url: ci_job_url,
        pipeline_url: ci_pipeline_url,
        pipeline_id: ci_pipeline_id,
        merge_request_iid: nil
      }
    }
  end

  def run_spec(&spec)
    spec ||= -> { it('spec', testcase: 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/1234') {} }

    describe_successfully('stats export', &spec).tap do |example_group|
      example_group.examples.each { |ex| ex.metadata[:file_path] = file_path }
    end
    send_stop_notification
  end

  around do |example|
    RSpec::Core::Sandbox.sandboxed do |config|
      config.formatter = QA::Support::Formatters::TestStatsFormatter

      config.append_after do |example|
        example.metadata[:api_fabrication] = Thread.current[:api_fabrication]
        example.metadata[:browser_ui_fabrication] = Thread.current[:browser_ui_fabrication]
      end

      config.before(:context) { RSpec.current_example = nil }

      example.run
    end
  end

  before do
    allow(InfluxDB2::Client).to receive(:new).with(url, token, **influx_client_args) { influx_client }
    allow(QA::Tools::TestResourceDataProcessor).to receive(:resources) { fabrication_resources }
  end

  context "without influxdb variables configured" do
    it "skips export without influxdb url" do
      stub_env('QA_INFLUXDB_URL', nil)
      stub_env('QA_INFLUXDB_TOKEN', nil)

      run_spec

      expect(influx_client).not_to have_received(:create_write_api)
    end

    it "skips export without influxdb token" do
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
      stub_env('CI_MERGE_REQUEST_IID', nil)
      stub_env('TOP_UPSTREAM_MERGE_REQUEST_IID', nil)
      stub_env('QA_RUN_TYPE', run_type)
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

    context 'with quarantined spec' do
      let(:quarantined) { 'true' }

      it 'exports data to influxdb with correct quarantine tag' do
        run_spec do
          it('spec', :quarantine, testcase: 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/1234') {}
        end

        expect(influx_write_api).to have_received(:write).once
        expect(influx_write_api).to have_received(:write).with(data: [data])
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

    context 'with fabrication runtimes' do
      let(:ui_fabrication) { 10 }
      let(:api_fabrication) { 4 }

      before do
        Thread.current[:api_fabrication] = api_fabrication
        Thread.current[:browser_ui_fabrication] = ui_fabrication
      end

      it 'exports data to influxdb with fabrication times' do
        run_spec

        expect(influx_write_api).to have_received(:write).once
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
  end
end
