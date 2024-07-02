# frozen_string_literal: true

RSpec.describe Gitlab::Cng::Commands::Create do
  include_context "with command testing helper"

  let(:kind_cluster) { instance_double(Gitlab::Cng::Kind::Cluster, create: nil) }

  before do
    allow(Gitlab::Cng::Kind::Cluster).to receive(:new).and_return(kind_cluster)
  end

  describe "cluster command" do
    let(:command_name) { "cluster" }

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
        name: "test-cluster",
        host_http_port: 80,
        host_ssh_port: 22
      })
    end
  end
end
