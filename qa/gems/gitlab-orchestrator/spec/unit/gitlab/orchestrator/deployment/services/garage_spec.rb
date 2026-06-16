# frozen_string_literal: true

RSpec.describe Gitlab::Orchestrator::Deployment::Services::Garage do
  subject(:garage) do
    described_class.new(
      kubeclient: kubeclient,
      helm: helm,
      namespace: namespace,
      release_name: release_name
    )
  end

  let(:namespace) { "gitlab" }
  let(:release_name) { "garage-test" }

  let(:kubeclient) do
    instance_double(Gitlab::Orchestrator::Kubectl::Client, create_resource: "secret/created")
  end

  let(:helm) do
    instance_double(Gitlab::Orchestrator::Helm::Client, upgrade: nil, uninstall: nil)
  end

  before do
    allow(garage).to receive(:execute_shell)
  end

  describe "attribute readers" do
    it "returns correct object_storage_secret_name" do
      expect(garage.object_storage_secret_name).to eq("garage-test-gitlab-object-storage")
    end

    it "returns correct s3cmd_secret_name" do
      expect(garage.s3cmd_secret_name).to eq("garage-test-gitlab-object-storage-s3cmd")
    end

    it "returns correct registry_storage_secret_name" do
      expect(garage.registry_storage_secret_name).to eq("garage-test-gitlab-registry-storage")
    end
  end

  describe "#install", :aggregate_failures do
    let(:access_key_id) { "GKtest-access-key" }
    let(:secret_access_key) { "test-secret-key" }
    let(:local_port) { 9999 }
    let(:spawn_pid) { 12_345 }
    let(:tcp_server) { instance_double(TCPServer, addr: ["AF_INET", local_port, "127.0.0.1", "127.0.0.1"], close: nil) }

    let(:api_responses) do
      {
        "/v2/GetClusterStatus" => { "nodes" => [{ "id" => "node-1", "isUp" => true }] },
        "/v2/UpdateClusterLayout" => { "version" => 0, "stagedRoleChanges" => [{ "id" => "node-1" }] },
        "/v2/ApplyClusterLayout" => { "message" => ["ok"], "layout" => { "version" => 1 } },
        "/v1/key" => { "accessKeyId" => access_key_id, "secretAccessKey" => secret_access_key },
        "/v1/bucket" => {},
        "/v1/bucket?list" => [{ "id" => "bucket-1" }, { "id" => "bucket-2" }],
        "/v1/bucket/allow" => {}
      }
    end

    before do
      allow(Dir).to receive(:mktmpdir).with("garage-chart-").and_return("/tmp/garage-chart-test")
      allow(FileUtils).to receive(:rm_rf)
      allow(garage).to receive(:execute_shell)
        .with(array_including("git", "clone")).and_return("")
      allow(garage).to receive(:execute_shell)
        .with(array_including("git", "-C", "/tmp/garage-chart-test", "sparse-checkout")).and_return("")
      allow(garage).to receive(:execute_shell)
        .with(array_including("kubectl", "wait", "pod")).and_return("")

      allow(SecureRandom).to receive(:hex).with(32).and_return("test-admin-token")
      allow(TCPServer).to receive(:new).with("127.0.0.1", 0).and_return(tcp_server)
      allow(Process).to receive(:spawn).and_return(spawn_pid)
      allow(Process).to receive(:kill)
      allow(Process).to receive(:wait)
      allow(TCPSocket).to receive(:new).with("127.0.0.1", local_port).and_return(instance_double(TCPSocket, close: nil))

      allow(Net::HTTP).to receive(:start) do |_host, _port, &block|
        http = instance_double(Net::HTTP)
        allow(http).to receive(:request) do |request|
          response_data = api_responses.fetch(request.path, api_responses[request.path.split("?").first] || {})
          body = response_data.to_json
          instance_double(Net::HTTPOK, is_a?: true, body: body)
        end
        block.call(http)
      end
    end

    it "runs the full install flow" do
      expect { garage.install }.to output(
        match(/Installing Garage/)
        .and(match(/Fetching Garage Helm chart/))
        .and(match(/Installing Garage Helm chart/))
        .and(match(/Waiting for Garage to become ready/))
        .and(match(/Configuring Garage cluster layout/))
        .and(match(/Creating Garage API key/))
        .and(match(/Creating 13 Garage buckets/))
        .and(match(/Granting bucket access to API key/))
        .and(match(/Creating object storage connection secret/))
        .and(match(/Creating s3cmd config secret/))
        .and(match(/Creating registry storage secret/))
      ).to_stdout

      expect(helm).to have_received(:upgrade).with(
        "garage-test",
        "/tmp/garage-chart-test/script/helm/garage",
        namespace: "gitlab",
        timeout: "5m",
        values: anything,
        args: ["--wait"]
      )
    end

    it "creates three kubernetes secrets" do
      expect { garage.install }.to output(anything).to_stdout

      expect(kubeclient).to have_received(:create_resource).exactly(3).times
    end

    it "creates object storage secret with correct name" do
      expect { garage.install }.to output(anything).to_stdout

      expect(kubeclient).to have_received(:create_resource).with(
        an_object_satisfying { |s|
          s.is_a?(Gitlab::Orchestrator::Kubectl::Resources::Secret) &&
            s.send(:resource_name) == "garage-test-gitlab-object-storage"
        }
      )
    end

    it "creates s3cmd secret with correct name" do
      expect { garage.install }.to output(anything).to_stdout

      expect(kubeclient).to have_received(:create_resource).with(
        an_object_satisfying { |s|
          s.is_a?(Gitlab::Orchestrator::Kubectl::Resources::Secret) &&
            s.send(:resource_name) == "garage-test-gitlab-object-storage-s3cmd"
        }
      )
    end

    it "creates registry storage secret with correct name" do
      expect { garage.install }.to output(anything).to_stdout

      expect(kubeclient).to have_received(:create_resource).with(
        an_object_satisfying { |s|
          s.is_a?(Gitlab::Orchestrator::Kubectl::Resources::Secret) &&
            s.send(:resource_name) == "garage-test-gitlab-registry-storage"
        }
      )
    end

    it "cleans up port-forward process" do
      expect { garage.install }.to output(anything).to_stdout

      expect(Process).to have_received(:kill).with("TERM", spawn_pid)
      expect(Process).to have_received(:wait).with(spawn_pid)
    end

    it "cleans up the temporary chart directory" do
      expect { garage.install }.to output(anything).to_stdout

      expect(FileUtils).to have_received(:rm_rf).with("/tmp/garage-chart-test")
    end
  end

  describe "#uninstall" do
    it "calls helm uninstall" do
      expect { garage.uninstall }.to output(/Uninstalling Garage/).to_stdout

      expect(helm).to have_received(:uninstall).with("garage-test", namespace: "gitlab", timeout: "5m")
    end

    context "when helm uninstall fails" do
      before do
        allow(helm).to receive(:uninstall).and_raise(Gitlab::Orchestrator::Helm::Client::Error, "release not found")
      end

      it "handles the error gracefully" do
        expect { garage.uninstall }.to output(
          match(/Uninstalling Garage/)
          .and(match(/Garage uninstall failed: release not found/))
        ).to_stdout
      end
    end
  end
end
