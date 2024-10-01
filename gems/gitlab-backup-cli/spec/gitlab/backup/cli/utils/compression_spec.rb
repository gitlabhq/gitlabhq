# frozen_string_literal: true

RSpec.describe Gitlab::Backup::Cli::Utils::Compression do
  let(:shell_command) { Gitlab::Backup::Cli::Shell::Command }

  describe '.compression_command' do
    it 'returns a Shell::Command instance' do
      expect(described_class.compression_command).to be_a(Gitlab::Backup::Cli::Shell::Command)
    end

    it 'returns a command for gzip compression' do
      command = described_class.compression_command
      expect(command.cmd_args.first).to eq('gzip -c -1')
    end
  end

  describe '.decompression_command' do
    it 'returns a Shell::Command instance' do
      expect(described_class.decompression_command).to be_a(Gitlab::Backup::Cli::Shell::Command)
    end

    it 'returns a command for gzip decompression' do
      command = described_class.decompression_command
      expect(command.cmd_args.first).to eq('gzip -cd')
    end
  end
end
