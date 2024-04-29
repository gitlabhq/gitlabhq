# frozen_string_literal: true

RSpec.describe Gitlab::Cng::CLI do
  let(:cli_klass) { Class.new(described_class) }
  let(:instance) { cli_klass.new }

  let(:command_klass) do
    Class.new(Thor) do
      desc "command", "description"
      def command; end
    end
  end

  before do
    cli_klass.register_commands(command_klass)

    allow(instance).to receive(:invoke)
  end

  it "registers command", :aggregate_failures do
    instance.command

    expect(instance).to have_received(:invoke).with(command_klass, "command")
    expect(cli_klass.commands["command"].to_h).to include({
      description: "description",
      long_description: nil,
      name: "command",
      options: {},
      usage: "command"
    })
  end
end
