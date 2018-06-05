module Pseudonymity
  class UploadService
    RemoteStorageUnavailableError = Class.new(StandardError)

    def initialize(options, progress = nil)
      @progress = progress || $stdout
      @output_dir = options.output_dir
      @upload_dir = options.upload_dir
    end

    def upload
      progress.puts "Uploading output files to remote storage #{remote_directory} ... "

      file_list.each do |file|
        upload_file(file, remote_directory)
      end
    end

    def upload_file(file, directory)
      progress.print "\t#{file} ... "

      if directory.files.create(key: File.join(@upload_dir, File.basename(file)),
                                body: File.open(file),
                                public: false)
        progress.puts "done".color(:green)
      else
        progress.puts "uploading CSV to #{remote_directory} failed".color(:red)
      end
    end

    def cleanup
      progress.print "Deleting tmp directory #{@output_dir} ... "
      return unless File.exist?(@output_dir)

      if FileUtils.rm_rf(@output_dir)
        progress.puts "done".color(:green)
      else
        progress.puts "failed".color(:red)
      end
    end

    private

    def config
      Gitlab.config.pseudonymizer
    end

    def remote_directory
      connection_settings = config.upload.connection
      if connection_settings.blank?
        progress.puts "Cannot upload files, make sure the `pseudonimizer.upload.connection` is set properly".color(:red)
        raise RemoteStorageUnavailableError.new(connection_settings)
      end

      connect_to_remote_directory(connection_settings)
    end

    def connect_to_remote_directory(connection_settings)
      # our settings use string keys, but Fog expects symbols
      connection = ::Fog::Storage.new(connection_settings.symbolize_keys)
      remote_dir = config.upload.remote_directory

      # We only attempt to create the directory for local backups. For AWS
      # and other cloud providers, we cannot guarantee the user will have
      # permission to create the bucket.
      if connection.service == ::Fog::Storage::Local
        connection.directories.create(key: remote_dir)
      else
        connection.directories.get(remote_dir)
      end
    end

    def file_list
      Dir[File.join(@output_dir, "*")]
    end
  end
end
