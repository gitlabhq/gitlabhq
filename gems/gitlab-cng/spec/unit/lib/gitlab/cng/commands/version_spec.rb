# frozen_string_literal: true

RSpec.describe Gitlab::Cng::Commands::Version do
  let(:version) { Gitlab::Cng::VERSION }

  it "defines a version command" do
    expect(described_class.commands["version"].to_h).to include({
      description: "Prints cng orchestrator version",
      long_description: nil,
      name: "version",
      options: {},
      usage: "version"
    })
  end

  it "prints the version" do
    expect { described_class.new.version }.to output(/#{version}/).to_stdout
  end
end
