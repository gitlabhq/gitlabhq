# frozen_string_literal: true

RSpec.describe Gitlab::Cng::CLI do
  shared_examples "command with help" do |args, help_output|
    it "shows help" do
      expect { cli.start(args) }.to output(/#{help_output}/).to_stdout
    end
  end

  subject(:cli) { described_class }

  describe "version command" do
    it_behaves_like "command with help", %w[help version], /Print cng orchestrator version/

    it "executes version command" do
      expect { cli.start(%w[version]) }.to output(/#{Gitlab::Cng::VERSION}/o).to_stdout
    end
  end

  describe "doctor command" do
    let(:command_instance) { Gitlab::Cng::Commands::Doctor.new }

    before do
      allow(Gitlab::Cng::Commands::Doctor).to receive(:new).and_return(command_instance)
      allow(command_instance).to receive(:doctor)
    end

    it_behaves_like "command with help", %w[help doctor], /Validate presence of all required system dependencies/

    it "invokes doctor command" do
      cli.start(%w[doctor])

      expect(command_instance).to have_received(:doctor)
    end
  end

  describe "create command" do
    context "with cluster subcommand" do
      let(:cluster_instance) { instance_double(Gitlab::Cng::Kind::Cluster, create: nil) }

      before do
        allow(Gitlab::Cng::Kind::Cluster).to receive(:new).and_return(cluster_instance)
      end

      it_behaves_like "command with help", %w[create help cluster], /Create kind cluster for local deployments/

      it "invokes cluster create command" do
        cli.start(%w[create cluster])

        expect(Gitlab::Cng::Kind::Cluster).to have_received(:new)
          .with(ci: false, name: "gitlab", host_http_port: 80, host_ssh_port: 22)
        expect(cluster_instance).to have_received(:create)
      end
    end

    context "with deployment subcommand" do
      let(:installation_instance) { instance_double(Gitlab::Cng::Deployment::Installation, create: nil) }

      context "with kind deployment" do
        let(:configuration_instance) { instance_double(Gitlab::Cng::Deployment::Configurations::Kind) }

        before do
          allow(Gitlab::Cng::Deployment::Installation).to receive(:new).and_return(installation_instance)
          allow(Gitlab::Cng::Deployment::Configurations::Kind).to receive(:new)
        end

        it_behaves_like "command with help", %w[create deployment help kind],
          /Create CNG deployment against local kind k8s cluster/

        it "invokes kind deployment" do
          cli.start(%w[create deployment kind --gitlab-domain 127.0.0.1.nip.io --skip-create-cluster])

          expect(installation_instance).to have_received(:create)
        end
      end
    end
  end
end
