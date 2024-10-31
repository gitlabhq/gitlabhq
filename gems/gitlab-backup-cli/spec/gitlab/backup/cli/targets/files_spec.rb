# frozen_string_literal: true

require 'spec_helper'
require 'active_support/testing/time_helpers'

RSpec.describe Gitlab::Backup::Cli::Targets::Files, feature_category: :backup_restore do
  include ActiveSupport::Testing::TimeHelpers

  let(:status_0) { instance_double(Process::Status, success?: true, exitstatus: 0) }
  let(:status_1) { instance_double(Process::Status, success?: false, exitstatus: 1) }
  let(:status_2) { instance_double(Process::Status, success?: false, exitstatus: 2) }
  let(:pipeline_status_failed) do
    Gitlab::Backup::Cli::Shell::Pipeline::Result.new(stderr: 'Cannot mkdir', status_list: [status_1, status_0])
  end

  let(:tmp_backup_restore_dir) { Dir.mktmpdir('files-target-restore') }

  let(:destination) { 'registry.tar.gz' }

  let(:context) { Gitlab::Backup::Cli::Context.build }

  let!(:workdir) do
    FileUtils.mkdir_p(context.backup_basedir)
    Pathname(Dir.mktmpdir('backup', context.backup_basedir))
  end

  let(:restore_target) { File.realpath(tmp_backup_restore_dir) }

  let(:backup_target) do
    %w[@pages.tmp lost+found @hashed].each do |folder|
      path = Pathname(tmp_backup_restore_dir).join(folder, 'something', 'else')

      FileUtils.mkdir_p(path)
      FileUtils.touch(path.join('artifacts.zip'))
    end

    File.realpath(tmp_backup_restore_dir)
  end

  before do
    allow(FileUtils).to receive(:mv).and_return(true)
    allow(File).to receive(:exist?).and_return(true)
  end

  after do
    FileUtils.rm_rf([restore_target, backup_target, destination], secure: true)
  end

  describe '#dump' do
    subject(:files) do
      described_class.new(context, backup_target, excludes: ['@pages.tmp'])
    end

    it 'raises no errors' do
      expect { files.dump(destination) }.not_to raise_error
    end

    it 'excludes tmp dirs from archive' do
      expect_next_instance_of(Gitlab::Backup::Cli::Shell::Pipeline) do |pipeline|
        tar_cmd = pipeline.shell_commands[0]

        expect(tar_cmd.cmd_args).to include('--exclude=lost+found')
        expect(tar_cmd.cmd_args).to include('--exclude=./@pages.tmp')

        allow(pipeline).to receive(:run!).and_call_original
      end

      files.dump(destination)
    end

    it 'raises an error on failure' do
      expect_next_instance_of(Gitlab::Backup::Cli::Shell::Pipeline::Result) do |result|
        expect(result).to receive(:success?).and_return(false)
      end

      expect do
        files.dump(destination)
      end.to raise_error(/Failed to create compressed file/)
    end
  end

  describe '#restore' do
    let(:source) { File.join(restore_target, 'backup.tar.gz') }
    let(:pipeline) { Gitlab::Backup::Cli::Shell::Pipeline.new(Gitlab::Backup::Cli::Shell::Command.new('echo 0')) }

    subject(:files) { described_class.new(context, restore_target) }

    before do
      FileUtils.touch(source)
      allow(Gitlab::Backup::Cli::Shell::Pipeline).to receive(:new).and_return(pipeline)
    end

    context 'when storage path exists' do
      before do
        allow(File).to receive(:exist?).with(restore_target).and_return(true)
      end

      it 'logs a warning about existing files' do
        expect(Gitlab::Backup::Cli::Output).to receive(:warning).with(/Ignoring existing files/)

        files.restore(source)
      end
    end

    context 'when pipeline execution is successful' do
      before do
        allow_next_instance_of(Gitlab::Backup::Cli::Shell::Pipeline::Result) do |result|
          allow(result).to receive(:success?).and_return(true)
        end
      end

      it 'does not raise an error' do
        expect { files.restore(source) }.not_to raise_error
      end
    end

    context 'when pipeline execution fails' do
      before do
        allow(files).to receive(:dump).and_return(true)
        allow_next_instance_of(Gitlab::Backup::Cli::Shell::Pipeline) do |pipeline|
          allow(pipeline).to receive(:run!).and_return(pipeline_status_failed)
        end
      end

      it 'raises a FileRestoreError' do
        expect { files.restore(source) }.to raise_error(Gitlab::Backup::Cli::Errors::FileRestoreError)
      end
    end

    context 'when pipeline execution has non-critical warnings' do
      let(:warning_message) { 'tar: .: Cannot mkdir: No such file or directory' }

      before do
        allow_next_instance_of(Gitlab::Backup::Cli::Shell::Pipeline::Result) do |result|
          allow(result).to receive(:success?).and_return(false)
          allow(result).to receive(:stderr).and_return(warning_message)
          allow(result).to receive(:status_list).and_return([status_0, status_2])
        end
      end

      it 'does not raise an error' do
        expect { files.restore(source) }.not_to raise_error
      end
    end
  end

  describe '#ignore_non_success?' do
    subject(:files) do
      described_class.new(context, '/var/gitlab-registry')
    end

    context 'if `tar` command exits with 1 exitstatus' do
      it 'returns true' do
        expect(
          files.send(:ignore_non_success?, 1, nil)
        ).to be_truthy
      end

      it 'outputs a warning' do
        expect do
          files.send(:ignore_non_success?, 1, nil)
        end.to output(/Ignoring tar exit status 1/).to_stdout
      end
    end

    context 'if `tar` command exits with 2 exitstatus with non-critical warning' do
      it 'returns true' do
        expect(
          files.send(:ignore_non_success?, 2, 'gtar: .: Cannot mkdir: No such file or directory')
        ).to be_truthy
      end

      it 'outputs a warning' do
        expect do
          files.send(:ignore_non_success?, 2, 'gtar: .: Cannot mkdir: No such file or directory')
        end.to output(/Ignoring non-success exit status/).to_stdout
      end
    end

    context 'if `tar` command exits with any other unlisted error' do
      it 'returns false' do
        expect(
          files.send(:ignore_non_success?, 2, 'unlisted_error')
        ).to be_falsey
      end
    end
  end
end
