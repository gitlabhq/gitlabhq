# frozen_string_literal: true

RSpec.shared_context "with command testing helper" do
  let(:command_instance) { described_class.new }

  # Invoke command with args
  #
  # @param [String] command
  # @param [Array] args
  # @return [void]
  def invoke_command(command, args = [], options = {})
    command_instance.invoke(command, args, options)
  end

  # Expect command to have attributes
  #
  # @param [String] command
  # @param [Hash] attributes
  # @return [void]
  def expect_command_to_include_attributes(command, attributes)
    expect(described_class.commands[command].to_h).to include(attributes)
  end
end
