module Backup
  class Uploads
    attr_reader :app_public_uploads_dir, :app_private_uploads_dir, :backup_public_uploads_dir,
     :backup_private_uploads_dir, :backup_dir, :backup_public_dir

    def initialize
      @app_public_uploads_dir = File.realpath(Rails.root.join('public', 'uploads'))
      @app_private_uploads_dir = File.realpath(Rails.root.join('uploads'))
      @backup_dir = Gitlab.config.backup.path
      @backup_public_dir = File.join(backup_dir, 'public')
      @backup_public_uploads_dir = File.join(backup_dir, 'public', 'uploads')
      @backup_private_uploads_dir = File.join(backup_dir, 'uploads')
    end

    # Copy uploads from public/uploads to backup/public/uploads and from /uploads to backup/uploads
    def dump
      FileUtils.mkdir_p(backup_public_uploads_dir)
      FileUtils.cp_r(app_public_uploads_dir, backup_public_dir)
      
      FileUtils.mkdir_p(backup_private_uploads_dir)
      FileUtils.cp_r(app_private_uploads_dir, backup_dir)
    end

    def restore
      backup_existing_public_uploads_dir
      backup_existing_private_uploads_dir

      FileUtils.cp_r(backup_public_uploads_dir, app_public_uploads_dir)
      FileUtils.cp_r(backup_private_uploads_dir, app_private_uploads_dir)
    end

    def backup_existing_public_uploads_dir
      timestamped_public_uploads_path = File.join(app_public_uploads_dir, '..', "uploads.#{Time.now.to_i}")
      if File.exists?(app_public_uploads_dir)
        FileUtils.mv(app_public_uploads_dir, timestamped_public_uploads_path)
      end
    end

    def backup_existing_private_uploads_dir
      timestamped_private_uploads_path = File.join(app_private_uploads_dir, '..', "uploads.#{Time.now.to_i}")
      if File.exists?(app_private_uploads_dir)
        FileUtils.mv(app_private_uploads_dir, timestamped_private_uploads_path)
      end
    end
  end
end
