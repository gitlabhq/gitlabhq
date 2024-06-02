# frozen_string_literal: true

RSpec.describe QA::Tools::Ci::TestMetrics do
  include QA::Support::Helpers::StubEnv

  let(:influx_client) { instance_double("InfluxDB2::Client", create_write_api: influx_write_api) }
  let(:influx_write_api) { instance_double("InfluxDB2::WriteApi", write: nil) }
  let(:gcs_client_options) { { force: true, content_type: 'application/json' } }
  let(:gcs_client) { double("Fog::Storage::GoogleJSON::Real", put_object: nil) } # rubocop:disable RSpec/VerifiedDoubles -- Class has `put_object` method but is not getting verified
  let(:logger) { instance_double("Logger", info: true, warn: true) }

  let(:glob) { "metrics_glob/*.json" }
  let(:paths) { ["/metrics_glob/metrics.json"] }
  let(:timestamp) { "2022-11-11 07:54:11 +0000" }
  let(:metrics_json) { metrics_data.to_json }

  let(:metrics_gcs_project_id) { 'metrics-gcs-project' }
  let(:metrics_gcs_creds) { 'metrics-gcs-creds' }
  let(:metrics_gcs_bucket_name) { 'metrics-gcs-bucket' }

  let(:metrics_data) do
    [
      {
        time: timestamp.to_time,
        name: "name",
        tags: {},
        fields: {}
      }
    ]
  end

  before do
    allow(InfluxDB2::Client).to receive(:new) { influx_client }

    allow(Fog::Storage::Google).to receive(:new)
                                     .with(google_project: metrics_gcs_project_id,
                                       google_json_key_string: metrics_gcs_creds)
                                     .and_return(gcs_client)
    allow(Gitlab::QA::TestLogger).to receive(:logger) { logger }
    allow(Dir).to receive(:glob).with(glob) { paths }
    allow(File).to receive(:read).with(paths.first) { metrics_json }

    stub_env('QA_INFLUXDB_URL', "test")
    stub_env('QA_INFLUXDB_TOKEN', "test")
    stub_env('QA_METRICS_GCS_PROJECT_ID', metrics_gcs_project_id)
    stub_env('QA_METRICS_GCS_CREDS', metrics_gcs_creds)
    stub_env('QA_METRICS_GCS_BUCKET_NAME', metrics_gcs_bucket_name)
  end

  context "with metrics files present" do
    it "exports saved metrics to influxdb and GCS", :aggregate_failures do
      described_class.export(glob)

      expect(influx_write_api).to have_received(:write).with(data: metrics_data, bucket: "e2e-test-stats-main")

      expect(gcs_client).to have_received(:put_object).with(metrics_gcs_bucket_name,
        anything, metrics_data.to_json, **gcs_client_options)
    end
  end

  context "without metrics files present" do
    let(:paths) { [] }

    it "exits without error" do
      described_class.export(glob)

      expect(influx_write_api).not_to have_received(:write)
      expect(logger).to have_received(:warn).with("No files matched pattern '#{glob}'")
    end
  end
end
