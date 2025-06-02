# frozen_string_literal: true

RSpec.describe Gitlab::Orchestrator::Commands::Metrics do
  include_context "with command testing helper"

  describe "serve command" do
    let(:command_name) { "serve" }
    let(:console_instance) { instance_double(Gitlab::Orchestrator::Metrics::Console, generate: true) }

    before do
      allow(Gitlab::Orchestrator::Metrics::Console).to receive(:new).and_return(console_instance)
    end

    it "invokes console generator with the correct type" do
      invoke_command(command_name, [], type: "cpu", max_width: 100, metrics_dir: "test")

      expect(Gitlab::Orchestrator::Metrics::Console).to have_received(:new).with(
        "test/metrics.json",
        data_points: nil,
        max_width: 100
      )
      expect(console_instance).to have_received(:generate).with("cpu")
    end
  end

  describe "start command" do
    let(:command_name) { "start" }
    let(:collector_instance) { instance_double(Gitlab::Orchestrator::Kubectl::Metrics::Collector, start: true) }

    before do
      allow(Gitlab::Orchestrator::Kubectl::Metrics::Collector).to receive(:new).and_return(collector_instance)
    end

    it "starts metrics collector with the correct arguments" do
      invoke_command(command_name, [], namespace: "custom-namespace", interval: 10, output_dir: "custom-output")

      expect(Gitlab::Orchestrator::Kubectl::Metrics::Collector).to have_received(:new).with(
        namespace: "custom-namespace",
        interval: 10,
        output_dir: "custom-output"
      )
      expect(collector_instance).to have_received(:start)
    end
  end

  describe "stop command" do
    let(:command_name) { "stop" }
    let(:pid_file) { File.join(Dir.mktmpdir('orchestrator'), "metrics.pid") }

    before do
      allow(Gitlab::Orchestrator::Helpers::Spinner).to receive(:spin).and_yield
      allow(Gitlab::Orchestrator::Helpers::Utils).to receive(:metrics_pid_file).and_return(pid_file)
      allow(Process).to receive(:kill)
      allow(Kernel).to receive(:sleep)

      File.write(pid_file, "2")
    end

    it "terminates process gracefully" do
      allow(Process).to receive(:kill).with(0, 2).and_raise(Errno::ESRCH)

      expect { invoke_command(command_name) }.to output(/Process 2 successfully terminated/).to_stdout
      expect(Kernel).to have_received(:sleep).once
    end

    it "terminates process with KILL if not responding to TERM signal" do
      expect { invoke_command(command_name) }.to output(
        /Process 2 didn't respond to TERM signal, used KILL to terminate/
      ).to_stdout

      expect(Kernel).to have_received(:sleep).exactly(5).times
    end
  end
end
