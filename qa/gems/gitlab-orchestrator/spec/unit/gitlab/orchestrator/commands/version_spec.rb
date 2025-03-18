# frozen_string_literal: true

RSpec.describe Gitlab::Orchestrator::Commands::Version do
  include_context "with command testing helper"

  let(:version) { Gitlab::Orchestrator::VERSION }

  it "defines a version command" do
    expect_command_to_include_attributes("version", {
      description: "Print orchestrator version",
      long_description: nil,
      name: "version",
      options: {},
      usage: "version"
    })
  end

  it "prints the version" do
    expect { invoke_command("version") }.to output(/#{version}/).to_stdout
  end
end
