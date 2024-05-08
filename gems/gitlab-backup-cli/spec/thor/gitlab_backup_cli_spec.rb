# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'gitlab-backup-cli commands', type: :thor do
  subject(:cli) { Gitlab::Backup::Cli::Runner }

  let(:expected_help_output) do
    <<~COMMAND
      GitLab Backup CLI commands:
        gitlab-backup-cli backup          # Manage repositories, database and files backup creation
        gitlab-backup-cli help [COMMAND]  # Describe available commands or one specific command
        gitlab-backup-cli restore         # Restore previously captured backup data
        gitlab-backup-cli version         # Display the version information

    COMMAND
  end

  describe 'Default behavior' do
    it 'returns subcommand information with listed known methods' do
      expect { cli.start([]) }.to output(expected_help_output).to_stdout
    end
  end

  describe 'gitlab-backup-cli help' do
    it 'returns subcommand information with listed known methods' do
      expect { cli.start(%w[help]) }.to output(expected_help_output).to_stdout
    end
  end

  describe 'gitlab-backup-cli version' do
    it 'returns the current version' do
      expect { cli.start(%w[version]) }.to output(
        /GitLab Backup CLI \(#{Gitlab::Backup::Cli::VERSION}\)\n/o
      ).to_stdout
    end
  end

  describe 'gitlab-backup-cli backup' do
    it 'returns a list of backup subcommands' do
      expect { cli.start(%w[backup]) }.to output(/Backup commands:.*/).to_stdout
    end
  end
end
