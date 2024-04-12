# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'gitlab-backup-cli backup subcommand', type: :thor do
  subject(:cli) { Gitlab::Backup::Cli::Runner }

  let(:backup_subcommand) { Gitlab::Backup::Cli::Commands::BackupSubcommand }
  let(:context) { build_fake_context }

  let(:expected_help_output) do
    <<~COMMAND
      Backup commands:
        gitlab-backup-cli backup all             # Creates a backup including repositories, database and local files
        gitlab-backup-cli backup help [COMMAND]  # Describe subcommands or one specific subcommand

    COMMAND
  end

  context 'with gitlab-backup-cli backup' do
    it 'returns a list of supported commands' do
      expect { cli.start(%w[backup]) }.to output(expected_help_output).to_stdout
    end
  end

  context 'with gitlab-backup-cli backup help' do
    it 'returns a list of supported commands' do
      expect { cli.start(%w[backup help]) }.to output(expected_help_output).to_stdout
    end
  end

  context 'with gitlab-backup-cli backup all' do
    it 'delegates backup execution to backup executor' do
      # Simulate real execution
      executor = Gitlab::Backup::Cli::BackupExecutor
      expect_next_instance_of(executor) do |instance|
        expect(instance).to receive(:execute)
      end
      expect_next_instance_of(backup_subcommand) do |instance|
        expect(instance).to receive(:build_context).and_return(context)
      end
      expect(Gitlab::Backup::Cli).to receive(:rails_environment!)

      expected_backup_output = /.*Starting GitLab backup.*Backup finished:.*/m
      expect { cli.start(%w[backup all]) }.to output(expected_backup_output).to_stdout
    end
  end
end
