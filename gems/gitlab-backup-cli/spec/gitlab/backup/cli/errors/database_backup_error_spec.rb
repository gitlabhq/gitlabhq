# frozen_string_literal: true

RSpec.describe Gitlab::Backup::Cli::Errors::DatabaseBackupError do
  let(:config) do
    {
      host: 'localhost',
      port: 5432,
      database: 'gitlab_db'
    }
  end

  let(:db_file_name) { 'gitlab_backup.sql.gz' }

  subject(:error) { described_class.new(config, db_file_name) }

  describe '#initialize' do
    it 'sets the config and db_file_name attributes' do
      expect(error.config).to eq(config)
      expect(error.db_file_name).to eq(db_file_name)
    end
  end

  describe '#message' do
    it 'returns a formatted error message' do
      expected_message = "Failed to create compressed file 'gitlab_backup.sql.gz' " \
                         "when trying to backup the main database:\n - host: " \
                         "'localhost'\n - port: '5432'\n - database: 'gitlab_db'"
      expect(error.message).to eq(expected_message)
    end

    it 'includes the correct database information in the message' do
      message = error.message
      expect(message).to include("host: '#{config[:host]}'")
      expect(message).to include("port: '#{config[:port]}'")
      expect(message).to include("database: '#{config[:database]}'")
    end

    it 'includes the correct db_file_name in the message' do
      expect(error.message).to include("'#{db_file_name}'")
    end
  end
end
