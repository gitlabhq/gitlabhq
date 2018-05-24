require 'backup/files'

module Backup
  class Registry < Files
    attr_reader :object_storage

    def initialize(object_storage=false)
      @object_storage = object_storage
      super('registry', Settings.registry.path)
    end

    def restore
      return super unless object_storage

      backup_existing_registry
      cleanup_registry
      restore_from_backup
    end

    private
    def failure_abort(error_message)
      puts "[Error] #{error_message}".color(:red)
      abort 'Restore registry failed'
    end

    def upload_to_object_storage(source_path, destination_s3_path)
      cmd = %W(s3cmd sync #{source_path} #{destination_s3_path})

      output, status = Gitlab::Popen.popen(cmd)

      failure_abort(output) unless status.zero?
    end

    def backup_existing_registry
      backup_file_name = "registry.#{Time.now.to_i}"
      cmd = %W(s3cmd sync s3://registry  s3://tmp/#{backup_file_name}/)

      output, status = Gitlab::Popen.popen(cmd)

      failure_abort(output) unless status.zero?
    end

    def cleanup_registry
      cmd = %W(s3cmd del --force --recursive s3://registry)
      output, status = Gitlab::Popen.popen(cmd)
      failure_abort(output) unless status.zero?
    end

    def restore_from_backup
      registry_tar_path = File.join(Gitlab.config.backup.path, 'registry.tar.gz')
      extracted_tar_path = File.join(Gitlab.config.backup.path, "tmp")
      FileUtils.mkdir_p(extracted_tar_path, mode: 0700)

      failure_abort("#{registry_tar_path} not found") unless File.exists?(registry_tar_path)

      untar_cmd = %W(tar -xf #{registry_tar_path} -C #{extracted_tar_path})

      output, status = Gitlab::Popen.popen(untar_cmd)

      failure_abort(output) unless status.zero?

      upload_to_object_storage("#{extracted_tar_path}/docker", "s3://registry")
    end
  end
end
