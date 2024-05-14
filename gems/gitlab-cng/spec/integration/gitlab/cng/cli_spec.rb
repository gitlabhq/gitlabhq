# frozen_string_literal: true

RSpec.describe Gitlab::Cng::CLI do
  shared_examples "command with help" do |args, help_output|
    it "shows help" do
      expect { cli.invoke(*args) }.to output(/#{help_output}/).to_stdout
    end
  end

  subject(:cli) { described_class.new }

  describe "version command" do
    it_behaves_like "command with help", [:help, ["version"]], /Print cng orchestrator version/

    it "executes version command" do
      expect { cli.invoke(:version) }.to output(/#{Gitlab::Cng::VERSION}/o).to_stdout
    end
  end

  describe "doctor command" do
    let(:command_instance) { Gitlab::Cng::Commands::Doctor.new }

    before do
      allow(Gitlab::Cng::Commands::Doctor).to receive(:new).and_return(command_instance)
      allow(command_instance).to receive(:doctor)
    end

    it_behaves_like "command with help", [:help, ["doctor"]], /Validate presence of all required system dependencies/

    it "invokes doctor command" do
      cli.invoke(:doctor)

      expect(command_instance).to have_received(:doctor)
    end
  end

  describe "create command" do
    context "with cluster subcommand" do
      let(:cluster_instance) { instance_double(Gitlab::Cng::Kind::Cluster, create: nil) }

      before do
        allow(Gitlab::Cng::Kind::Cluster).to receive(:new).and_return(cluster_instance)
      end

      it_behaves_like "command with help", [:help, %w[create cluster]], /Create kind cluster for local deployments/

      it "invokes cluster create command" do
        cli.invoke(:create, %w[cluster])

        expect(Gitlab::Cng::Kind::Cluster).to have_received(:new).with(ci: false, name: "gitlab")
        expect(cluster_instance).to have_received(:create)
      end
    end
  end
end
