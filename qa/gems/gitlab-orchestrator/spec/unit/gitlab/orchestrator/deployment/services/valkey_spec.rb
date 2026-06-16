# frozen_string_literal: true

RSpec.describe Gitlab::Orchestrator::Deployment::Services::Valkey do
  subject(:valkey) do
    described_class.new(
      kubeclient: kubeclient,
      helm: helm,
      namespace: namespace,
      release_name: release_name
    )
  end

  let(:namespace) { "gitlab" }
  let(:release_name) { "valkey-test" }

  let(:kubeclient) do
    instance_double(Gitlab::Orchestrator::Kubectl::Client, create_resource: "secret/valkey-test-auth created")
  end

  let(:helm) do
    instance_double(Gitlab::Orchestrator::Helm::Client, add_helm_chart: nil, upgrade: nil, uninstall: nil)
  end

  before do
    allow(SecureRandom).to receive(:hex).with(16).and_return("a1b2c3d4e5f6a7b8")
    allow(valkey).to receive(:execute_shell)
  end

  describe "attribute readers" do
    it "returns correct host" do
      expect(valkey.host).to eq("valkey-test.gitlab.svc.cluster.local")
    end

    it "returns correct auth_secret_name" do
      expect(valkey.auth_secret_name).to eq("valkey-test-auth")
    end

    it "returns correct auth_secret_key" do
      expect(valkey.auth_secret_key).to eq("default")
    end
  end

  describe "#install", :aggregate_failures do
    let(:expected_values) do
      {
        auth: {
          enabled: true,
          usersExistingSecret: "valkey-test-auth",
          aclUsers: {
            default: {
              permissions: "~* &* +@all",
              passwordKey: "default"
            }
          }
        },
        dataStorage: {
          enabled: true
        }
      }.deep_stringify_keys.to_yaml
    end

    it "creates auth secret and installs helm chart" do
      expect { valkey.install }.to output(
        match(/Installing Valkey/)
        .and(match(/Creating Valkey auth secret/))
        .and(match(/Adding Valkey Helm chart repo/))
        .and(match(/Installing Valkey Helm chart/))
      ).to_stdout

      expect(kubeclient).to have_received(:create_resource).with(
        Gitlab::Orchestrator::Kubectl::Resources::Secret.new("valkey-test-auth", "default", "a1b2c3d4e5f6a7b8")
      )
      expect(helm).to have_received(:add_helm_chart).with("valkey", "https://valkey-io.github.io/valkey-helm")
      expect(helm).to have_received(:upgrade).with(
        "valkey-test",
        "valkey/valkey",
        namespace: "gitlab",
        timeout: "5m",
        values: expected_values,
        args: ["--wait"]
      )
    end
  end

  describe "#uninstall" do
    it "calls helm uninstall" do
      expect { valkey.uninstall }.to output(/Uninstalling Valkey/).to_stdout

      expect(helm).to have_received(:uninstall).with("valkey-test", namespace: "gitlab", timeout: "5m")
    end

    context "when helm uninstall fails" do
      before do
        allow(helm).to receive(:uninstall).and_raise(Gitlab::Orchestrator::Helm::Client::Error, "release not found")
      end

      it "handles the error gracefully" do
        expect { valkey.uninstall }.to output(
          match(/Uninstalling Valkey/)
          .and(match(/Valkey uninstall failed: release not found/))
        ).to_stdout
      end
    end
  end
end
