# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'gitlab-backup-cli restore subcommand', type: :thor do
  subject(:cli) { Gitlab::Backup::Cli::Runner }

  let(:context) { build_fake_context }

  let(:expected_help_output) do
    <<~COMMAND
      Restore commands:
        gitlab-backup-cli restore all BACKUP_ID   # Restores a backup including repositories, database and local files
        gitlab-backup-cli restore help [COMMAND]  # Describe subcommands or one specific subcommand

      Options:
        [--backup-bucket=BACKUP_BUCKET]                                                    # When backing up object storage, this is the bucket to backup to
        [--wait-for-completion], [--no-wait-for-completion], [--skip-wait-for-completion]  # Wait for object storage backups to complete
                                                                                           # Default: true
        [--registry-bucket=REGISTRY_BUCKET]                                                # When backing up registry from object storage, this is the source bucket
        [--service-account-file=SERVICE_ACCOUNT_FILE]                                      # JSON file containing the Google service account credentials
                                                                                           # Default: /etc/gitlab/backup-account-credentials.json

    COMMAND
  end

  context 'with gitlab-backup-cli restore' do
    it 'returns a list of supported commands' do
      expect { cli.start(%w[restore]) }.to output(expected_help_output).to_stdout
    end
  end

  context 'with gitlab-backup-cli restore help' do
    it 'returns a list of supported commands' do
      expect { cli.start(%w[restore help]) }.to output(expected_help_output).to_stdout
    end
  end

  context 'with gitlab-backup-cli restore all', :silence_output do
    let(:restore_subcommand) { Gitlab::Backup::Cli::Commands::RestoreSubcommand }
    let(:executor) { Gitlab::Backup::Cli::RestoreExecutor }
    let(:backup_id) { "1715018771_2024_05_06_17.0.0-pre" }

    before do
      allow(Gitlab::Backup::Cli).to receive(:rails_environment!)

      expect_next_instance_of(restore_subcommand) do |instance|
        allow(instance).to receive(:build_context).and_return(context)
      end
    end

    it 'delegates restore execution to restore executor' do
      # Simulate real execution
      expect_next_instance_of(executor) do |instance|
        expect(instance).to receive(:execute)
      end

      expected_backup_output = /
        .* Restoring\ GitLab\ backup\ #{Regexp.escape(backup_id)}
        .* GitLab\ restoration\ of\ backup\ #{Regexp.escape(backup_id)}\ finished
        .*
      /mx

      expect { cli.start(%W[restore all #{backup_id}]) }.to output(expected_backup_output).to_stdout
    end

    it 'displays an error message when an error is raised' do
      backup_error = Gitlab::Backup::Cli::Error.new('Custom error message')

      # Simulate an error during execution
      expect_next_instance_of(executor) do |instance|
        expect(instance).to receive(:execute).and_raise(backup_error)
      end

      expected_output = /.*GitLab Backup failed: Custom error message.*\)/m

      expect do
        cli.start(%W[restore all #{backup_id}])
      end.to raise_error(SystemExit) { |err| expect(err.status).to eq(1) }.and output(expected_output).to_stderr
    end
  end
end
