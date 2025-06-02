# frozen_string_literal: true

RSpec.describe Gitlab::Orchestrator::Kubectl::Metrics::Collector do
  subject(:collector) { described_class.new(namespace: namespace, interval: 5, output_dir: output_dir) }

  let(:namespace) { "test-namespace" }
  let(:output_dir) { Dir.mktmpdir("orchestrator") }
  let(:kubectl) { instance_double(Gitlab::Orchestrator::Kubectl::Client) }

  before do
    allow(kubectl).to receive(:get_namespace)

    allow(Gitlab::Orchestrator::Kubectl::Client).to receive(:new).with(namespace).and_return(kubectl)
    allow(Gitlab::Orchestrator::Helpers::Spinner).to receive(:spin).and_yield

    allow(FileUtils).to receive(:mkdir_p).and_call_original
    allow(FileUtils).to receive(:rm_f).and_call_original
    allow(Process).to receive(:fork).and_return(pid)
    allow(Signal).to receive(:trap)
  end

  describe "foreground process" do
    let(:pid) { 2 }

    it "performs setup and forks process" do
      expect { expect { collector.start }.to output.to_stdout }.to raise_error(SystemExit)

      expect(FileUtils).to have_received(:mkdir_p).with(output_dir)
      expect(kubectl).to have_received(:get_namespace)
      expect(Signal).to have_received(:trap).with("TERM")
    end
  end

  describe "background process" do
    let(:pid) { nil }
    let(:metrics) { [] }

    let(:logfile) { File.join(output_dir, "metrics-collector.log") }
    let(:pidfile) { File.join(output_dir, "collector.pid") }
    let(:metrics_file) { File.join(output_dir, "metrics.json") }

    before do
      allow(Process).to receive(:pid).and_return(2)

      allow($stdout).to receive(:reopen)
      allow($stderr).to receive(:reopen)
      allow($stdout).to receive(:puts)

      allow(Gitlab::Orchestrator::Helpers::Utils).to receive(:metrics_pid_file).and_return(
        File.join(output_dir, "collector.pid")
      )

      allow(collector).to receive(:sleep).with(1)
      allow(collector).to receive(:sleep).with(5)
      allow(collector).to receive(:loop).and_yield
      allow(kubectl).to receive(:top_pods).and_return(metrics)
    end

    it "creates pidfile and logfile" do
      collector.start

      expect(File.read(pidfile)).to eq("2")
      expect(File.read(logfile)).not_to be_empty
      expect($stdout).to have_received(:reopen).with(logfile, "a")
      expect($stderr).to have_received(:reopen).with(logfile, "a")
    end

    context "with shutdown signal" do
      before do
        allow(Signal).to receive(:trap).with("TERM").and_yield
      end

      it "defines shutdown sequence" do
        expect { collector.start }.to raise_error(SystemExit)

        expect(FileUtils).to have_received(:rm_f).with(pidfile)
      end
    end

    context "with metrics collection" do
      let(:timestamp) { Time.now }
      let(:metrics) { ["pod1 100m 128Mi", "pod2 200m 256Mi"] }
      let(:resource) { { cpu: "50m", memory: "64Mi" } }

      def container_spec(type)
        {
          spec: {
            containers: [
              { resources: { type => resource } }
            ]
          }
        }
      end

      before do
        allow(Time).to receive(:now).and_return(timestamp)

        allow(kubectl).to receive(:pod).with("pod1").and_return(container_spec(:requests))
        allow(kubectl).to receive(:pod).with("pod2").and_return(container_spec(:limits))
      end

      it "saves metrics in JSON format" do
        collector.start

        expect(JSON.load_file(metrics_file)).to eq(
          "pod1" => {
            "requests" => { "cpu" => 50, "memory" => 64 },
            "limits" => { "cpu" => 0, "memory" => 0 },
            "metrics" => [
              { "timestamp" => timestamp.to_i, "cpu" => 100, "memory" => 128 }
            ]
          },
          "pod2" => {
            "requests" => { "cpu" => 0, "memory" => 0 },
            "limits" => { "cpu" => 50, "memory" => 64 },
            "metrics" => [
              { "timestamp" => timestamp.to_i, "cpu" => 200, "memory" => 256 }
            ]
          })
      end
    end
  end
end
