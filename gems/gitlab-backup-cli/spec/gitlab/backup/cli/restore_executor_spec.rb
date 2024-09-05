# frozen_string_literal: true

RSpec.describe Gitlab::Backup::Cli::RestoreExecutor do
  let(:context) { build_fake_context }
  let(:backup_id) { "1715018771_2024_05_06_17.0.0-pre" }

  subject(:executor) do
    described_class.new(
      context: context,
      backup_id: backup_id
    )
  end

  after do
    executor.release!
  end

  describe '#initialize' do
    it 'creates a workdir' do
      expect(executor.workdir).to be_a(Pathname)
      expect(executor.workdir).to be_directory
    end

    it 'initializes archive_directory' do
      expected_archive_directory = context.backup_basedir.join(backup_id)
      expect(executor.archive_directory).to eq(expected_archive_directory)
    end
  end

  describe '#release!' do
    it 'removes the workdir' do
      expect { executor.release! }.to change { executor.workdir.exist? }.from(true).to(false)
    end
  end
end
