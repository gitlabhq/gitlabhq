# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Backup::Cli::Shell::Command do
  let(:envdata) do
    { 'CUSTOM' => 'data' }
  end

  subject(:command) { described_class }

  describe '#initialize' do
    it 'accepts required attributes' do
      expect { command.new('ls', '-l') }.not_to raise_exception
    end

    it 'accepts optional attributes' do
      expect { command.new('ls', '-l', env: envdata) }.not_to raise_exception
    end
  end

  describe '#capture' do
    it 'returns stdout from executed command' do
      expected_output = 'my custom content'

      result = command.new('echo', expected_output).capture

      expect(result.stdout.chomp).to eq(expected_output)
      expect(result.stderr).to be_empty
    end

    it 'returns stderr from executed command' do
      expected_output = 'my custom error content'

      result = command.new('sh', '-c', "echo #{expected_output} > /dev/stderr").capture

      expect(result.stdout).to be_empty
      expect(result.stderr.chomp).to eq(expected_output)
    end

    it 'returns a Process::Status from the executed command' do
      result = command.new('pwd').capture

      expect(result.status).to be_a(Process::Status)
      expect(result.status).to respond_to(:exited?, :termsig, :stopsig, :exitstatus, :success?, :pid)
    end

    it 'returns the execution duration' do
      result = command.new('sleep 0.1').capture

      expect(result.duration).to be > 0.1
    end
  end
end
