# See http://doc.gitlab.com/ce/development/migration_style_guide.html
# for more information on how to write migrations for GitLab.

class MovePersonalSnippetFilesIntoCorrectFolder < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers
  disable_ddl_transaction!

  DOWNTIME = false
  NEW_DIRECTORY = File.join('/uploads', '-', 'system', 'personal_snippet')
  OLD_DIRECTORY = File.join('/uploads', 'system', 'personal_snippet')

  def up
    return unless file_storage?

    BackgroundMigrationWorker.perform_async('MovePersonalSnippetFiles',
                                            [OLD_DIRECTORY, NEW_DIRECTORY])
  end

  def down
    return unless file_storage?

    BackgroundMigrationWorker.perform_async('MovePersonalSnippetFiles',
                                            [NEW_DIRECTORY, OLD_DIRECTORY])
  end

  def file_storage?
    CarrierWave::Uploader::Base.storage == CarrierWave::Storage::File
  end
end
