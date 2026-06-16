# frozen_string_literal: true

RSpec.describe Gitlab::Orchestrator::Deployment::Configurations::Cleanup::Kind do
  let(:kind_cleanup) { described_class.new("gitlab") }

  let(:kubeclient) { instance_double(Gitlab::Orchestrator::Kubectl::Client) }
  let(:helmclient) { instance_double(Gitlab::Orchestrator::Helm::Client, uninstall: nil) }

  let(:garage) { instance_double(Gitlab::Orchestrator::Deployment::Services::Garage, uninstall: nil) }
  let(:cnpg) { instance_double(Gitlab::Orchestrator::Deployment::Services::CloudNativePG, uninstall: nil) }
  let(:valkey) { instance_double(Gitlab::Orchestrator::Deployment::Services::Valkey, uninstall: nil) }

  before do
    allow(Gitlab::Orchestrator::Kubectl::Client).to receive(:new).and_return(kubeclient)
    allow(Gitlab::Orchestrator::Helm::Client).to receive(:new).and_return(helmclient)
    allow(Gitlab::Orchestrator::Deployment::Services::Garage).to receive(:new).and_return(garage)
    allow(Gitlab::Orchestrator::Deployment::Services::CloudNativePG).to receive(:new).and_return(cnpg)
    allow(Gitlab::Orchestrator::Deployment::Services::Valkey).to receive(:new).and_return(valkey)
    allow(kubeclient).to receive(:delete_resource).with("secret", "gitlab-initial-root-password").and_return("output-1")
    allow(kubeclient).to receive(:delete_resource).with("configmap", "pre-receive-hook").and_return("output-2")
  end

  it "performs object cleanup", :aggregate_failures do
    expect { kind_cleanup.run }.to output(
      match(/Removing secret 'gitlab-initial-root-password'/)
        .and(match(/output-1/))
        .and(match(/Removing configmap 'pre-receive-hook'/))
        .and(match(/output-2/))
    ).to_stdout

    expect(garage).to have_received(:uninstall)
    expect(cnpg).to have_received(:uninstall)
    expect(valkey).to have_received(:uninstall)
  end
end
