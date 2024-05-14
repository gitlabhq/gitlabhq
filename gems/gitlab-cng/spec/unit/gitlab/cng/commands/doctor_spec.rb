# frozen_string_literal: true

RSpec.describe Gitlab::Cng::Commands::Doctor do
  include_context "with command testing helper"

  let(:spinner) { instance_double(Gitlab::Cng::Helpers::Spinner) }
  let(:command_name) { "doctor" }
  let(:tools_present) { true }
  let(:tools) { %w[docker kind kubectl helm] }

  before do
    allow(Gitlab::Cng::Helpers::Spinner).to receive(:new) { spinner }
    allow(spinner).to receive(:spin).and_yield

    tools.each { |tool| allow(TTY::Which).to receive(:exist?).with(tool).and_return(tools_present) }
  end

  it "defines a doctor command" do
    expect_command_to_include_attributes(command_name, {
      description: "Validate presence of all required system dependencies",
      long_description: nil,
      name: command_name,
      options: {},
      usage: command_name
    })
  end

  context "with all tools present" do
    it "does not raise an error", :aggregate_failures do
      expect do
        expect { invoke_command(command_name) }.not_to raise_error
      end.to output(/All system dependencies are present/).to_stdout
    end
  end

  context "with missing tools" do
    let(:tools_present) { false }

    it "exits and prints missing dependencies error", :aggregate_failures do
      expect do
        expect { invoke_command(command_name) }.to raise_error(SystemExit)
      end.to output(/The following system dependencies are missing: #{tools.join(', ')}/).to_stdout
    end
  end
end
