# frozen_string_literal: true

RSpec.describe Gitlab::Backup::Cli::Errors::FileBackupError do
  let(:app_files_dir) { '/path/to/app/files' }
  let(:backup_tarball) { '/path/to/backup.tar.gz' }
  let(:error) { described_class.new(app_files_dir, backup_tarball) }

  describe '#initialize' do
    it 'sets the storage_path attribute' do
      expect(error.storage_path).to eq(app_files_dir)
    end

    it 'sets the backup_tarball attribute' do
      expect(error.backup_tarball).to eq(backup_tarball)
    end
  end

  describe '#message' do
    it 'returns a formatted error message' do
      expected_message = "Failed to create compressed file '/path/to/backup.tar.gz' " \
                         "when trying to backup the following paths: '/path/to/app/files' "
      expect(error.message).to eq(expected_message)
    end

    it 'includes the backup_tarball in the message' do
      expect(error.message).to include(backup_tarball)
    end

    it 'includes the storage_path in the message' do
      expect(error.message).to include(app_files_dir)
    end
  end
end
