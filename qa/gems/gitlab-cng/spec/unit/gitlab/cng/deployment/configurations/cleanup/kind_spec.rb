# frozen_string_literal: true

RSpec.describe Gitlab::Cng::Deployment::Configurations::Cleanup::Kind do
  let(:kind_cleanup) { described_class.new("gitlab") }

  let(:kubeclient) { instance_double(Gitlab::Cng::Kubectl::Client) }

  before do
    allow(Gitlab::Cng::Kubectl::Client).to receive(:new).and_return(kubeclient)
    allow(kubeclient).to receive(:delete_resource).with("secret", "gitlab-initial-root-password").and_return("output-1")
    allow(kubeclient).to receive(:delete_resource).with("configmap", "pre-receive-hook").and_return("output-2")
  end

  it "performs object cleanup" do
    expect { kind_cleanup.run }.to output(
      match(/Removing secret 'gitlab-initial-root-password'/)
        .and(match(/output-1/))
        .and(match(/Removing configmap 'pre-receive-hook'/))
        .and(match(/output-2/))
    ).to_stdout
  end
end
