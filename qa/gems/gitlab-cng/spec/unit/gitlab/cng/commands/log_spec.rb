# frozen_string_literal: true

RSpec.describe Gitlab::Cng::Commands::Log do
  include_context "with command testing helper"

  let(:kubeclient) { instance_double(Gitlab::Cng::Kubectl::Client) }

  before do
    allow(Gitlab::Cng::Kubectl::Client).to receive(:new).with("gitlab").and_return(kubeclient)
  end

  describe "pods command" do
    let(:command_name) { "pods" }

    let(:pod_logs) do
      {
        "pod-1" => "log-1",
        "pod-2" => "log-2"
      }
    end

    before do
      allow(kubeclient).to receive(:pod_logs).and_return(pod_logs)
      pod_logs.each { |name, log| allow(File).to receive(:write).with("#{name}.log", log) }
    end

    it "defines pods command" do
      expect_command_to_include_attributes(command_name, {
        description: "Log application pods",
        name: command_name,
        usage: "#{command_name} [NAME]"
      })
    end

    it "prints all pod logs" do
      expect { invoke_command(command_name) }.to output(
        match(/Logs for pod 'pod-1'/).and(match(/log-1/).and(match(/Logs for pod 'pod-2'/).and(match(/log-2/))))
      ).to_stdout
    end

    it "fetches log for single pod only" do
      expect { invoke_command(command_name, ["pod-1"], {}) }.to output.to_stdout
      expect(kubeclient).to have_received(:pod_logs).with(["pod-1"], containers: "all", since: "1h")
    end

    it "saves logs to files", :aggregate_failures do
      expect { invoke_command(command_name, [], { save: true }) }.to output(
        match(/saving logs to separate files in the current directory/).and(match(/created file 'pod-1.log'/))
      ).to_stdout

      expect(File).to have_received(:write).with("pod-1.log", "log-1")
      expect(File).to have_received(:write).with("pod-2.log", "log-2")
    end

    it "raises error when no pod is found" do
      allow(kubeclient).to receive(:pod_logs).and_raise(
        Gitlab::Cng::Kubectl::Client::Error, "No pods found in namespace 'gitlab'"
      )

      expect do
        expect { invoke_command(command_name) }.to output(/No pods found in namespace 'gitlab'/).to_stdout
      end.to raise_error(SystemExit)
    end

    it "prints warning with --no-fail-on-missing-pods argument" do
      allow(kubeclient).to receive(:pod_logs).and_raise(
        Gitlab::Cng::Kubectl::Client::Error, "No pods found in namespace 'gitlab'"
      )

      expect do
        invoke_command(command_name, [], { fail_on_missing_pods: false })
      end.to output(/No pods found in namespace 'gitlab'/).to_stdout
    end
  end

  describe "events command" do
    let(:command_name) { "events" }
    let(:events) { "events" }

    before do
      allow(kubeclient).to receive(:events).and_return(events)
      allow(File).to receive(:write).with("deployment-events.log", events)
    end

    it "defines events command" do
      expect_command_to_include_attributes(command_name, {
        description: "Log cluster events",
        name: command_name,
        usage: command_name
      })
    end

    it "prints events" do
      expect { invoke_command(command_name) }.to output(
        match(/Fetching events/).and(match(/#{events}\n/))
      ).to_stdout
    end

    it "saves events to file" do
      expect { invoke_command(command_name, [], { save: true }) }.to output(
        match(/saving events to separate file in the current directory/).and(
          match(/created file 'deployment-events.log'/)
        )
      ).to_stdout
    end
  end
end
