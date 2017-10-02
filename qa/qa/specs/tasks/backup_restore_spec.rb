require 'byebug'

module QA
  describe 'backup GitLab installation' do
    it 'a new backup is created with the Rake task' do
      config = QA::Runtime::Config.new
      backup = Tasks::Backup.new(config.backup_path)
      before_count = backup.list_backups.count

      backup.create_backup

      expect(backup.list_backups.count).to eq(before_count + 1)
    end
  end
end
