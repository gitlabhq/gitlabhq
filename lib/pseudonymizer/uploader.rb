module Pseudonymizer
  class Uploader
    RemoteStorageUnavailableError = Class.new(StandardError)

    def self.object_store_credentials
      Gitlab.config.pseudonymizer.upload.connection.to_hash.deep_symbolize_keys
    end

    def self.remote_directory
      Gitlab.config.pseudonymizer.upload.remote_directory
    end

    def initialize(options, progress = nil)
      @progress = progress || $stdout
      @config = options.config
      @output_dir = options.output_dir
      @upload_dir = options.upload_dir
      @remote_dir = self.class.remote_directory
      @connection_params = self.class.object_store_credentials
    end

    def upload
      progress.puts "Uploading output files to remote storage #{remote_directory} ... "

      file_list.each do |file|
        upload_file(file, remote_directory)
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

    attr_reader :progress

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

    def remote_directory
      if @connection_params.blank?
        progress.puts "Cannot upload files, make sure the `pseudonimizer.upload.connection` is set properly".color(:red)
        raise RemoteStorageUnavailableError.new(@config)
      end

      connect_to_remote_directory
    end

    def connect_to_remote_directory
      # our settings use string keys, but Fog expects symbols
      connection = ::Fog::Storage.new(@connection_params)

      # We only attempt to create the directory for local backups. For AWS
      # and other cloud providers, we cannot guarantee the user will have
      # permission to create the bucket.
      if connection.service == ::Fog::Storage::Local
        connection.directories.create(key: @remote_dir)
      else
        connection.directories.get(@remote_dir)
      end
    end

    def file_list
      Dir[File.join(@output_dir, "*")]
    end
  end
end
