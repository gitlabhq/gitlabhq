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
end
