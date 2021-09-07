# frozen_string_literal: true

require 'rspec/core/sandbox'

describe QA::Support::Formatters::TestStatsFormatter do
  include QA::Support::Helpers::StubEnv
  include QA::Specs::Helpers::RSpec

  let(:url) { "http://influxdb.net" }
  let(:token) { "token" }
  let(:ci_timestamp) { "2021-02-23T20:58:41Z" }
  let(:ci_job_name) { "test-job 1/5" }
  let(:ci_job_url) { "url" }
  let(:ci_pipeline_id) { "123" }
  let(:run_type) { 'staging-full' }
  let(:influx_client) { instance_double('InfluxDB2::Client', create_write_api: influx_write_api) }
  let(:influx_write_api) { instance_double('InfluxDB2::WriteApi', write: nil) }

  let(:influx_client_args) do
    {
      bucket: 'e2e-test-stats',
      org: 'gitlab-qa',
      use_ssl: false,
      precision: InfluxDB2::WritePrecision::NANOSECOND
    }
  end

  let(:data) do
    {
      name: 'test-stats',
      time: DateTime.strptime(ci_timestamp).to_time,
      tags: {
        name: "stats export #{spec_name}",
        file_path: './spec/support/formatters/test_stats_formatter_spec.rb',
        status: :passed,
        reliable: reliable,
        quarantined: quarantined,
        retried: "false",
        job_name: "test-job",
        merge_request: "false",
        run_type: run_type
      },
      fields: {
        id: './spec/support/formatters/test_stats_formatter_spec.rb[1:1]',
        run_time: 0,
        retry_attempts: 0,
        job_url: ci_job_url,
        pipeline_id: ci_pipeline_id
      }
    }
  end

  def run_spec(&spec)
    describe_successfully('stats export', &spec)
    send_stop_notification
  end

  around do |example|
    RSpec::Core::Sandbox.sandboxed do |config|
      config.formatter = QA::Support::Formatters::TestStatsFormatter

      config.before(:context) { RSpec.current_example = nil }

      example.run
    end
  end

  before do
    allow(InfluxDB2::Client).to receive(:new).with(url, token, **influx_client_args) { influx_client }
  end

  context "without influxdb variables configured" do
    it "skips export without influxdb url" do
      stub_env('QA_INFLUXDB_URL', nil)
      stub_env('QA_INFLUXDB_TOKEN', nil)

      run_spec do
        it('skips export') {}
      end

      expect(influx_client).not_to have_received(:create_write_api)
    end

    it "skips export without influxdb token" do
      stub_env('QA_INFLUXDB_URL', url)
      stub_env('QA_INFLUXDB_TOKEN', nil)

      run_spec do
        it('skips export') {}
      end

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
      stub_env('CI_PIPELINE_ID', ci_pipeline_id)
      stub_env('CI_MERGE_REQUEST_IID', nil)
      stub_env('TOP_UPSTREAM_MERGE_REQUEST_IID', nil)
      stub_env('QA_RUN_TYPE', run_type)
    end

    context 'with reliable spec' do
      let(:reliable) { 'true' }
      let(:quarantined) { 'false' }

      it 'exports data to influxdb' do
        run_spec do
          it('exports data', :reliable) {}
        end

        expect(influx_write_api).to have_received(:write).with(data: [data])
      end
    end

    context 'with quarantined spec' do
      let(:reliable) { 'false' }
      let(:quarantined) { 'true' }

      it 'exports data to influxdb' do
        run_spec do
          it('exports data', :quarantine) {}
        end

        expect(influx_write_api).to have_received(:write).with(data: [data])
      end
    end
  end
end
