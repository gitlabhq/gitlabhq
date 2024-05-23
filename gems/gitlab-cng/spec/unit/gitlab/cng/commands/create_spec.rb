# frozen_string_literal: true

RSpec.describe Gitlab::Cng::Commands::Create do
  include_context "with command testing helper"

  describe "cluster command" do
    let(:command_name) { "cluster" }
    let(:kind_cluster) { instance_double(Gitlab::Cng::Kind::Cluster, create: nil) }

    before do
      allow(Gitlab::Cng::Kind::Cluster).to receive(:new).and_return(kind_cluster)
    end

    it "defines cluster command" do
      expect_command_to_include_attributes(command_name, {
        description: "Create kind cluster for local deployments",
        name: command_name,
        usage: command_name
      })
    end

    it "invokes kind cluster creation with correct arguments" do
      invoke_command(command_name, [], { ci: true, name: "test-cluster" })

      expect(kind_cluster).to have_received(:create)
      expect(Gitlab::Cng::Kind::Cluster).to have_received(:new).with({
        ci: true,
        name: "test-cluster"
      })
    end
  end

  describe "deployment command" do
    let(:command_name) { "deployment" }
    let(:deployment_install) { instance_double(Gitlab::Cng::Deployment::Installation, create: nil) }

    before do
      allow(Gitlab::Cng::Deployment::Installation).to receive(:new).and_return(deployment_install)
    end

    it "defines cluster command" do
      expect_command_to_include_attributes(command_name, {
        description: "Create CNG deployment from official GitLab Helm chart",
        name: command_name,
        usage: "#{command_name} [NAME]"
      })
    end

    it "invokes kind cluster creation with correct arguments" do
      invoke_command(command_name, [], { configuration: "kind", ci: true, namespace: "gitlab" })

      expect(deployment_install).to have_received(:create)
      expect(Gitlab::Cng::Deployment::Installation).to have_received(:new).with(
        "gitlab",
        configuration: "kind",
        ci: true,
        namespace: "gitlab"
      )
    end
  end
end
