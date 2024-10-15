# frozen_string_literal: true

RSpec.describe Gitlab::Cng::Commands::Doctor do
  include_context "with command testing helper"

  let(:spinner) { instance_double(Gitlab::Cng::Helpers::Spinner) }
  let(:command_name) { "doctor" }
  let(:missing_tools) { [] }

  before do
    allow(Gitlab::Cng::Helpers::Spinner).to receive(:new) { spinner }
    allow(spinner).to receive(:spin).and_yield

    allow(TTY::Which).to receive(:exist?).and_return(true)
    missing_tools.each { |tool| allow(TTY::Which).to receive(:exist?).with(tool).and_return(false) }
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
        expect { invoke_command(command_name) }.not_to raise_error(SystemExit)
      end.to output(/All system dependencies are present/).to_stdout
    end
  end

  context "with missing optional tool" do
    let(:missing_tools) { %w[tar] }

    it "prints missing dependencies warning", :aggregate_failures do
      expect do
        expect { invoke_command(command_name) }.not_to raise_error(SystemExit)
      end.to output(/Following optional system dependecies are missing: tar/).to_stdout
    end
  end

  context "with missing required tools" do
    let(:missing_tools) { %w[docker kind] }

    it "prints missing dependencies error and raises SystemExit", :aggregate_failures do
      expect do
        expect { invoke_command(command_name) }.to raise_error(SystemExit)
      end.to output(/Following required system dependencies are missing: docker, kind/).to_stdout
    end
  end
end
