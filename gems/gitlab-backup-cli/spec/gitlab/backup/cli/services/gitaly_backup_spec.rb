# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Backup::Cli::Services::GitalyBackup do
  let(:context) { build_test_context }
  let(:gitaly_backup) { described_class.new(context) }

  before do
    Gitlab::Backup::Cli::Models::Base.initialize_connection!(context: context)
  end

  describe '#start' do
    context 'when creating a backup' do
      it 'starts the gitaly-backup process with the correct arguments' do
        backup_repos_path = '/path/to/backup/repos'
        backup_id = 'abc123'
        expected_args = ['create', '-path', backup_repos_path, '-layout', 'manifest', '-id', backup_id]
        expect(Open3).to receive(:popen2).with(instance_of(Hash), instance_of(String), *expected_args)

        gitaly_backup.start(:create, backup_repos_path, backup_id: backup_id)
      end
    end

    context 'when restoring a backup' do
      it 'starts the gitaly-backup process with the correct arguments' do
        backup_repos_path = '/path/to/backup/repos'
        backup_id = 'abc123'
        remove_all_repositories = %w[repo1 repo2]
        expected_args = ['restore', '-path', backup_repos_path, '-layout', 'manifest', '-remove-all-repositories',
          'repo1,repo2', '-id', backup_id]
        expect(Open3).to receive(:popen2).with(instance_of(Hash), instance_of(String), *expected_args)

        gitaly_backup.start(:restore, backup_repos_path, backup_id: backup_id,
          remove_all_repositories: remove_all_repositories)
      end
    end

    context 'when an invalid type is provided' do
      it 'raises an error' do
        expect do
          gitaly_backup.start(:invalid,
            '/path/to/backup/repos')
        end.to raise_error(Gitlab::Backup::Cli::Errors::GitalyBackupError, /unknown backup type: invalid/)
      end
    end

    context 'when already started' do
      it 'raises an error' do
        gitaly_backup.instance_variable_set(:@thread, Thread.new { true })
        expect do
          gitaly_backup.start(:create,
            '/path/to/backup/repos')
        end.to raise_error(Gitlab::Backup::Cli::Errors::GitalyBackupError, /already started/)
      end
    end
  end

  describe '#finish!' do
    context 'when not started' do
      it 'returns without raising an error' do
        expect { gitaly_backup.finish! }.not_to raise_error
      end
    end

    context 'when started' do
      let(:thread) { instance_double('Thread', join: nil, value: instance_double(Process::Status, exitstatus: 0)) }

      before do
        gitaly_backup.instance_variable_set(:@thread, thread)
        gitaly_backup.instance_variable_set(:@input_stream, instance_double('InputStream', close: nil))
      end

      it 'closes the input stream and joins the thread' do
        input_stream = gitaly_backup.instance_variable_get(:@input_stream)
        expect(input_stream).to receive(:close)
        expect(thread).to receive(:join)

        gitaly_backup.finish!
      end

      context 'when the process exits with a non-zero status' do
        let(:thread) { instance_double('Thread', join: nil, value: instance_double(Process::Status, exitstatus: 1)) }

        it 'raises an error' do
          expect do
            gitaly_backup.finish!
          end.to raise_error(Gitlab::Backup::Cli::Errors::GitalyBackupError, /gitaly-backup exit status 1/)
        end
      end
    end
  end

  describe '#enqueue' do
    context 'when not started' do
      it 'raises an error' do
        expect do
          gitaly_backup.enqueue(double)
        end.to raise_error(Gitlab::Backup::Cli::Errors::GitalyBackupError, /not started/)
      end
    end

    context 'when started' do
      let(:input_stream) { instance_double('InputStream', puts: nil) }

      before do
        gitaly_backup.instance_variable_set(:@input_stream, input_stream)
        gitaly_backup.instance_variable_set(:@thread, Thread.new { true })
      end

      context 'with a project repository' do
        let(:container) { build(:project) }

        it 'schedules a backup job with the correct parameters' do
          expected_json = {
            storage_name: 'storage',
            relative_path: container.disk_path,
            gl_project_path: 'group/project',
            always_create: true
          }.to_json

          expect(input_stream).to receive(:puts).with(expected_json)

          gitaly_backup.enqueue(container, always_create: true)
        end
      end

      context 'with a wiki repository' do
        let(:container) { build(:project_wiki) }

        it 'schedules a backup job with the correct parameters' do
          expected_json = {
            storage_name: 'wiki_storage',
            relative_path: container.disk_path,
            gl_project_path: 'group/project.wiki',
            always_create: false
          }.to_json

          expect(input_stream).to receive(:puts).with(expected_json)

          gitaly_backup.enqueue(container)
        end
      end

      context 'with a personal snippet repository' do
        let(:container) { build(:personal_snippet, id: 1) }

        it 'schedules a backup job with the correct parameters' do
          expected_json = {
            storage_name: 'snippets_storage',
            relative_path: container.disk_path,
            gl_project_path: 'snippets/1',
            always_create: false
          }.to_json

          expect(input_stream).to receive(:puts).with(expected_json)

          gitaly_backup.enqueue(container)
        end
      end

      context 'with a project snippet repository' do
        let(:container) { build(:project_snippet, id: 1) }

        it 'schedules a backup job with the correct parameters' do
          expected_json = {
            storage_name: 'snippets_storage',
            relative_path: container.disk_path,
            gl_project_path: 'group/myproject/snippets/1',
            always_create: false
          }.to_json

          expect(input_stream).to receive(:puts).with(expected_json)

          gitaly_backup.enqueue(container)
        end
      end

      context 'with a design repository' do
        let(:container) { build(:project_design_management) }

        it 'schedules a backup job with the correct parameters' do
          expected_json = {
            storage_name: 'design_storage',
            relative_path: container.disk_path,
            gl_project_path: 'group/project.design',
            always_create: false
          }.to_json

          expect(input_stream).to receive(:puts).with(expected_json)

          gitaly_backup.enqueue(container)
        end
      end

      context 'with an invalid container class' do
        it 'raises an error' do
          expect do
            gitaly_backup.enqueue(nil)
          end.to raise_error(Gitlab::Backup::Cli::Errors::GitalyBackupError, /not a valid container/)
        end
      end
    end
  end
end
