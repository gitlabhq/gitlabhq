# frozen_string_literal: true

RSpec.describe QA::Tools::Ci::TestMetrics do
  include QA::Support::Helpers::StubEnv

  let(:influx_client) { instance_double("InfluxDB2::Client", create_write_api: influx_write_api) }
  let(:influx_write_api) { instance_double("InfluxDB2::WriteApi", write: nil) }
  let(:logger) { instance_double("Logger", info: true, warn: true) }

  let(:glob) { "metrics_glob/*.json" }
  let(:paths) { ["/metrics_glob/metrics.json"] }
  let(:timestamp) { "2022-11-11 07:54:11 +0000" }
  let(:metrics_json) { metrics_data.to_json }

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
    allow(Gitlab::QA::TestLogger).to receive(:logger) { logger }
    allow(Dir).to receive(:glob).with(glob) { paths }
    allow(File).to receive(:read).with(paths.first) { metrics_json }

    stub_env('QA_INFLUXDB_URL', "test")
    stub_env('QA_INFLUXDB_TOKEN', "test")
  end

  context "with metrics files present" do
    it "exports saved metrics to influxdb" do
      described_class.export(glob)

      expect(influx_write_api).to have_received(:write).with(data: metrics_data, bucket: "e2e-test-stats-main")
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
