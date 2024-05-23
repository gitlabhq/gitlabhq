# frozen_string_literal: true

RSpec.describe Gitlab::Cng::Deployment::Installation do
  subject(:installation) do
    described_class.new(
      "gitlab",
      configuration: "kind",
      namespace: "gitlab",
      ci: false
    )
  end

  let(:command_status) { instance_double(Process::Status, success?: true) }
  let(:kubeclient) { instance_double(Gitlab::Cng::Kubectl::Client, create_namespace: "", create_resource: "") }
  let(:license_secret) { Gitlab::Cng::Kubectl::Resources::Secret.new("gitlab-license", "license", "test") }

  let(:password_secret) do
    Gitlab::Cng::Kubectl::Resources::Secret.new("gitlab-initial-root-password", "password", "test")
  end

  let(:hook_configmap) do
    Gitlab::Cng::Kubectl::Resources::Configmap.new(
      "pre-receive-hook",
      "hook.sh",
      <<~SH
        #!/usr/bin/env bash

        if [[ $GL_PROJECT_PATH =~ 'reject-prereceive' ]]; then
          echo 'GL-HOOK-ERR: Custom error message rejecting prereceive hook for projects with GL_PROJECT_PATH matching pattern reject-prereceive'
          exit 1
        fi
      SH
    )
  end

  before do
    allow(Gitlab::Cng::Helpers::Spinner).to receive(:spin).and_yield
    allow(Gitlab::Cng::Kubectl::Client).to receive(:new).with("gitlab").and_return(kubeclient)

    allow(Open3).to receive(:popen2e).and_return(["", command_status])
  end

  around do |example|
    ClimateControl.modify({ "QA_EE_LICENSE" => "test", "GITLAB_ADMIN_PASSWORD" => "test" }) { example.run }
  end

  it "runs setup and helm deployment", :aggregate_failures do
    expect { installation.create }.to output(/Creating CNG deployment 'gitlab' using 'kind' configuration/).to_stdout

    expect(Open3).to have_received(:popen2e).with({}, *%w[helm repo add gitlab https://charts.gitlab.io])
    expect(Open3).to have_received(:popen2e).with({}, *%w[helm repo update gitlab])

    expect(kubeclient).to have_received(:create_namespace)
    expect(kubeclient).to have_received(:create_resource).with(license_secret)
    expect(kubeclient).to have_received(:create_resource).with(password_secret)
    expect(kubeclient).to have_received(:create_resource).with(hook_configmap)
  end
end
