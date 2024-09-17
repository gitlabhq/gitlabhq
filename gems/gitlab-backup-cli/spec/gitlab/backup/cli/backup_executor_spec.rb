# frozen_string_literal: true

RSpec.describe Gitlab::Backup::Cli::BackupExecutor do
  let(:context) { build_fake_context }

  subject(:executor) { described_class.new(context: context) }

  after do
    executor.release!
  end

  describe '#initialize' do
    it 'creates a workdir' do
      expect(executor.workdir).to be_a(Pathname)
      expect(executor.workdir).to be_directory
    end

    it 'initializes metadata' do
      expect(executor.metadata).to be_a(Gitlab::Backup::Cli::Metadata::BackupMetadata)
    end
  end

  describe '#write_metadata!' do
    it 'writes metadata to the workdir' do
      metadata_file = executor.workdir.join(Gitlab::Backup::Cli::Metadata::BackupMetadata::METADATA_FILENAME)

      expect { executor.send(:write_metadata!) }.to change { metadata_file.exist? }.from(false).to(true)
    end
  end

  describe '#release!' do
    it 'removes the workdir' do
      expect { executor.release! }.to change { executor.workdir.exist? }.from(true).to(false)
    end
  end
end
