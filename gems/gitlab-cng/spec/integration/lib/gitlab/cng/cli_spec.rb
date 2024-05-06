# frozen_string_literal: true

RSpec.describe Gitlab::Cng::CLI do
  let(:cli) { described_class.new }

  describe "version command" do
    it "shows version command help" do
      expect { cli.invoke(:help, ["version"]) }.to output(/Prints cng orchestrator version/).to_stdout
    end

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

    it "shows doctor command help" do
      expect { cli.invoke(:help, ["doctor"]) }.to output(
        /Validate presence of all required system dependencies/
      ).to_stdout
    end

    it "invokes doctor command" do
      cli.invoke(:doctor)

      expect(command_instance).to have_received(:doctor)
    end
  end
end
