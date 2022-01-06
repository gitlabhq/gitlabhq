# frozen_string_literal: true

module Backup
  Error = Class.new(StandardError)

  class FileBackupError < Backup::Error
    attr_reader :app_files_dir, :backup_tarball

    def initialize(app_files_dir, backup_tarball)
      @app_files_dir = app_files_dir
      @backup_tarball = backup_tarball
    end

    def message
      "Failed to create compressed file '#{backup_tarball}' when trying to backup the following paths: '#{app_files_dir}'"
    end
  end

  class DatabaseBackupError < Backup::Error
    attr_reader :config, :db_file_name

    def initialize(config, db_file_name)
      @config = config
      @db_file_name = db_file_name
    end

    def message
      "Failed to create compressed file '#{db_file_name}' when trying to backup the main database:\n - host: '#{config[:host]}'\n - port: '#{config[:port]}'\n - database: '#{config[:database]}'"
    end
  end
end
