# frozen_string_literal: true

RSpec.describe Gitlab::Orchestrator::CLI do
  shared_examples "command with help" do |args, help_output|
    it "shows help for #{args.last} command" do
      expect { cli.start(args) }.to output(/#{help_output}/).to_stdout
    end
  end

  shared_examples "executable command" do |command_class, args|
    let(:command_instance) { command_class.new }

    before do
      allow(command_class).to receive(:new).and_return(command_instance)
      allow(command_instance).to receive(args.last.to_sym)
    end

    it "correctly invokes #{args} command" do
      cli.start(args)

      expect(command_instance).to have_received(args.last.to_sym)
    end
  end

  subject(:cli) { described_class }

  describe "version command" do
    it_behaves_like "command with help", %w[help version], /Print orchestrator version/
    it_behaves_like "executable command", Gitlab::Orchestrator::Commands::Version, %w[version]
  end

  describe "doctor command" do
    it_behaves_like "command with help", %w[help doctor], /Validate presence of all required system dependencies/
    it_behaves_like "executable command", Gitlab::Orchestrator::Commands::Doctor, %w[doctor]
  end

  describe "log command" do
    it_behaves_like "command with help", %w[log help events],
      /Output events from the cluster for specific namespace/
    it_behaves_like "command with help", %w[log help pods],
      /Log application pods, where NAME is full or part of the pod name/

    it_behaves_like "executable command", Gitlab::Orchestrator::Commands::Log, %w[log pods]
    it_behaves_like "executable command", Gitlab::Orchestrator::Commands::Log, %w[log events]
  end

  describe "metrics command" do
    it_behaves_like "command with help", %w[metrics help serve],
      /Visualize metrics data collected by background process./
    it_behaves_like "command with help", %w[metrics help start],
      /Periodically collect and store metrics for pods./
    it_behaves_like "command with help", %w[metrics help stop],
      /Stop the metrics collector background process./

    it_behaves_like "executable command", Gitlab::Orchestrator::Commands::Metrics, %w[metrics serve]
    it_behaves_like "executable command", Gitlab::Orchestrator::Commands::Metrics, %w[metrics start]
    it_behaves_like "executable command", Gitlab::Orchestrator::Commands::Metrics, %w[metrics stop]
  end

  describe "create command" do
    context "with deployment subcommand" do
      context "with kind deployment" do
        it_behaves_like "command with help", %w[create deployment help kind],
          /Create CNG deployment against local kind k8s cluster/

        it_behaves_like "executable command", Gitlab::Orchestrator::Commands::Subcommands::Deployment,
          %w[create deployment kind]
      end
    end
  end
end
