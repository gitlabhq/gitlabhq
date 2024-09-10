# frozen_string_literal: true

RSpec.describe Gitlab::Cng::Kubectl::Client do
  subject(:client) { described_class.new("gitlab") }

  let(:resource) { Gitlab::Cng::Kubectl::Resources::Configmap.new("config", "some", "value") }

  before do
    allow(client).to receive(:execute_shell).and_return("cmd-output")
  end

  it "creates namespace" do
    expect(client.create_namespace).to eq("cmd-output")
    expect(client).to have_received(:execute_shell).with(%w[kubectl create namespace gitlab])
  end

  it "creates custom resource" do
    expect(client.create_resource(resource)).to eq("cmd-output")
    expect(client).to have_received(:execute_shell).with(%w[kubectl apply -n gitlab -f -], stdin_data: resource.json)
  end

  describe "#execute" do
    before do
      allow(client).to receive(:execute_shell).with(
        %w[kubectl get pods -n gitlab --output jsonpath={.items[*].metadata.name}], stdin_data: nil
      ).and_return("some-pod-123 test-pod-123")
    end

    it "executes command in a pod" do
      expect(client.execute("test-pod", ["ls"], container: "toolbox")).to eq("cmd-output")
      expect(client).to have_received(:execute_shell).with(
        %w[kubectl exec test-pod-123 -n gitlab -c toolbox -- ls],
        stdin_data: nil
      )
    end
  end

  describe "#pod_logs" do
    let(:all_pods_json) do
      {
        items: [
          {
            metadata: {
              name: "some-pod-123"
            },
            spec: {
              containers: [
                {
                  name: "toolbox"
                }
              ]
            }
          },
          {
            metadata: {
              name: "test-pod-123"
            },
            spec: {
              containers: [
                {
                  name: "gitaly"
                }
              ]
            }
          }
        ]
      }.to_json
    end

    before do
      allow(client).to receive(:execute_shell).with(
        %w[kubectl get pods -n gitlab --output json],
        stdin_data: nil
      ).and_return(all_pods_json)
    end

    def mock_pod_logs(name, containers_arg)
      allow(client).to receive(:execute_shell).with(
        %W[kubectl logs pod/#{name} -n gitlab --since=1h --prefix=true #{containers_arg}],
        stdin_data: nil
      ).and_return("#{name} logs")
    end

    context "with logs for specific pod and default container" do
      let(:pod_name) { "some-pod-123" }

      before do
        mock_pod_logs(pod_name, "--container=toolbox")
      end

      it "returns logs for pod" do
        logs = nil

        expect { logs = client.pod_logs([pod_name]) }.to output(/Fetching logs for pods '#{pod_name}'/).to_stdout
        expect(logs).to eq({ pod_name => "#{pod_name} logs" })
      end
    end

    context "with logs for all pods and containers" do
      let(:pods) { %w[some-pod-123 test-pod-123] }

      before do
        pods.each { |name| mock_pod_logs(name, "--all-containers=true") }
      end

      it "returns logs for pod" do
        logs = nil

        expect { logs = client.pod_logs([], containers: "all") }.to output(
          /Fetching logs for pods '#{pods.join(', ')}'/
        ).to_stdout
        expect(logs).to eq(pods.to_h { |name| [name, "#{name} logs"] })
      end
    end

    context "with no pods matching specific pod" do
      it "raises an error" do
        expect { client.pod_logs(%w[missing-pod]) }.to raise_error("No pods matched: missing-pod")
      end
    end

    context "with no pods returned from cluster" do
      let(:all_pods_json) { { items: [] }.to_json }

      it "raises an error" do
        expect { client.pod_logs([]) }.to raise_error("No pods found in namespace 'gitlab'")
      end
    end
  end

  describe "#events" do
    before do
      allow(client).to receive(:execute_shell).with(
        ["kubectl", "get", "events", "-n", "gitlab", *args],
        stdin_data: nil
      ).and_return("some events")
    end

    context "with default format" do
      let(:args) { %w[--sort-by=lastTimestamp] }

      it "return events in default format" do
        expect(client.events).to eq("some events")
      end
    end

    context "with json format" do
      let(:args) { %w[--sort-by=lastTimestamp --output=json] }

      it "return events in default format" do
        expect(client.events(json_format: true)).to eq("some events")
      end
    end
  end

  it "executes custom command in pod" do
    allow(client).to receive(:execute_shell)
      .with(%w[kubectl get pods -n gitlab --output jsonpath={.items[*].metadata.name}], stdin_data: nil)
      .and_return("some-pod-123 test-pod-123")

    expect(client.execute("test-pod", ["ls"], container: "toolbox")).to eq("cmd-output")
    expect(client).to have_received(:execute_shell).with(
      %w[kubectl exec test-pod-123 -n gitlab -c toolbox -- ls], stdin_data: nil
    )
  end

  it "deletes resource" do
    expect(client.delete_resource("secret", "test")).to eq("cmd-output")
    expect(client).to have_received(:execute_shell).with(
      %w[kubectl delete secret test -n gitlab --ignore-not-found=true --wait], stdin_data: nil
    )
  end
end
