# frozen_string_literal: true

RSpec.describe Gitlab::Cng::Commands::Doctor do
  subject(:command) { described_class.new }

  let(:spinner) { instance_double(Gitlab::Cng::Helpers::Spinner) }
  let(:command_name) { "doctor" }
  let(:tools_present) { true }
  let(:tools) { %w[docker kind kubectl helm] }

  before do
    allow(Gitlab::Cng::Helpers::Spinner).to receive(:new) { spinner }
    allow(spinner).to receive(:spin).and_yield
    allow(command).to receive(:puts)

    tools.each { |tool| allow(TTY::Which).to receive(:exist?).with(tool).and_return(tools_present) }
  end

  it "defines a doctor command" do
    expect(described_class.commands[command_name].to_h).to include({
      description: "Validate presence of all required system dependencies",
      long_description: nil,
      name: command_name,
      options: {},
      usage: command_name
    })
  end

  context "with all tools present" do
    it "does not raise an error", :aggregate_failures do
      expect { command.doctor }.not_to raise_error
      expect(command).to have_received(:puts).with(/All system dependencies are present/)
    end
  end

  context "with missing tools" do
    let(:tools_present) { false }

    it "exits and prints missing dependencies error", :aggregate_failures do
      expect { command.doctor }.to raise_error(SystemExit)
      expect(command).to have_received(:puts).with(/The following system dependencies are missing: #{tools.join(', ')}/)
    end
  end
end
