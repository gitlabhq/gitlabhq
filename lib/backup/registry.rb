require 'backup/files'

module Backup
  class Registry < Files
    attr_reader :object_storage

    def initialize(object_storage=false)
      self.object_storage = object_storage
      super('registry', Settings.registry.path)
    end

    def restore
      return super unless object_storage

      backup_existing_registy
      cleanup_registry
      restore_from_backup
    end

    private
    def backup_existing_registry
      backup_file_name = "registry.#{Time.now.utc}"
      cmd = %W(s3cmd sync s3://registry/docker  s3://tmp/#{backup_file_name})

      output, status = Gitlab::Popen.popen(cmd)

      unless status.zero?
        progress.puts "[WARNING] Executing #{cmd}".color(:orange)
        progress.puts "[Error] #{output}"
      end
    end

    def cleanup_registry
      cmd = %W(s3cmd del --recursive s3://registry)
      output, status = Gitlab::Popen.popen(cmd)
      unless status.zero?
        progress.puts "[Error] Failed to clean up registry #{output}".color(:red)
        return
      end
    end

    def restore_from_backup
      registry_tar_path = File.join(Gitlab.config.backup.path, 'registry.tar.gz')
      extracted_tar_path = File.join(Gitlab.config.backup.path, "tmp")
      FileUtils.mkdir_p(extracted_tar_path, mode: 0700)

      unless File.exists(registry_tar_path)
        progress.puts "#{registry_tar_path} not found".color(:red)
        return
      end

      untar_cmd = %W(tar -xf #{registry_tar_path} -C #{extracted_tar_path})

      output, status = Gitlab::Popen.popen(untar_cmd)

      unless status.zero?
        progress.puts "[Error] #{output}".color(:red)
        return
      end

      upload_to_object_storage("#{extracted_tar_path}/*", "s3://registry")
    end
  end

  def upload_to_object_storage(source_path, destination_s3_path)
    cmd = %W(s3cmd sync #{source_path} #{destination_s3_path})

    output, status = Gitlab::Popen.popen(cmd)

    unless status.zero?
      progress.puts "[Error] Could not upload to object storage #{output}".color(:red)
    end
  end
end
