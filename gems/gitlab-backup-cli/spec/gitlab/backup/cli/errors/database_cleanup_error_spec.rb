# frozen_string_literal: true

RSpec.describe Gitlab::Backup::Cli::Errors::DatabaseCleanupError do
  let(:task) { 'gitlab:task' }
  let(:path) { fixtures_path }
  let(:error) { 'error message from task execution' }

  subject(:database_error) { described_class.new(task: task, path: path, error: error) }

  describe '#initialize' do
    it 'sets task, path and error attributes' do
      expect(database_error.path).to eq(path)
      expect(database_error.task).to eq(task)
      expect(database_error.error).to eq(error)
    end
  end
end
