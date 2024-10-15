# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'gitlab-backup-cli backup subcommand', type: :thor do
  subject(:cli) { Gitlab::Backup::Cli::Runner }

  let(:context) { build_fake_context }

  let(:expected_help_output) do
    <<~COMMAND
      Backup commands:
        gitlab-backup-cli backup all             # Creates a backup including repositories, database and local files
        gitlab-backup-cli backup help [COMMAND]  # Describe subcommands or one specific subcommand

      Options:
        [--backup-bucket=BACKUP_BUCKET]                                                    # When backing up object storage, this is the bucket to backup to
        [--wait-for-completion], [--no-wait-for-completion], [--skip-wait-for-completion]  # Wait for object storage backups to complete
                                                                                           # Default: true
        [--registry-bucket=REGISTRY_BUCKET]                                                # When backing up registry from object storage, this is the source bucket
        [--service-account-file=SERVICE_ACCOUNT_FILE]                                      # JSON file containing the Google service account credentials
                                                                                           # Default: /etc/gitlab/backup-account-credentials.json

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

  context 'with gitlab-backup-cli backup all', :silence_output do
    let(:backup_subcommand) { Gitlab::Backup::Cli::Commands::BackupSubcommand }
    let(:executor) { Gitlab::Backup::Cli::BackupExecutor }

    before do
      allow(Gitlab::Backup::Cli).to receive(:rails_environment!)

      expect_next_instance_of(backup_subcommand) do |instance|
        allow(instance).to receive(:build_context).and_return(context)
      end
    end

    it 'delegates backup execution to backup executor' do
      # Simulate real execution
      expect_next_instance_of(executor) do |instance|
        expect(instance).to receive(:execute)
      end

      expected_backup_output = /.*Starting GitLab backup.*Backup finished:.*/m
      expect { cli.start(%w[backup all]) }.to output(expected_backup_output).to_stdout
    end

    it 'displays an error message when an error is raised' do
      backup_error = Gitlab::Backup::Cli::Error.new('Custom error message')

      # Simulate an error during execution
      expect_next_instance_of(executor) do |instance|
        expect(instance).to receive(:execute).and_raise(backup_error)
      end

      expected_output = /.*GitLab Backup failed: Custom error message.*\)/m

      expect do
        cli.start(%w[backup all])
      end.to raise_error(SystemExit) { |err| expect(err.status).to eq(1) }.and output(expected_output).to_stderr
    end
  end
end
