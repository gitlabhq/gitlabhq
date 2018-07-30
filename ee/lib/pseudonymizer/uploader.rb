module Pseudonymizer
  ObjectStorageUnavailableError = Class.new(StandardError)

  class Uploader
    include Gitlab::Utils::StrongMemoize

    RemoteStorageUnavailableError = Class.new(StandardError)

    # Our settings use string keys, but Fog expects symbols
    def self.object_store_credentials
      Gitlab.config.pseudonymizer.upload.connection.to_hash.deep_symbolize_keys
    end

    def self.remote_directory
      Gitlab.config.pseudonymizer.upload.remote_directory
    end

    def initialize(options, progress_output: nil)
      @progress_output = progress_output || $stdout
      @config = options.config
      @output_dir = options.output_dir
      @upload_dir = options.upload_dir
      @remote_dir = self.class.remote_directory
      @connection_params = self.class.object_store_credentials
    end

    def available?
      !connect_to_remote_directory.nil?
    rescue
      false
    end

    def upload
      progress_output.puts "Uploading output files to remote storage #{remote_directory}:"

      file_list.each do |file|
        upload_file(file, remote_directory)
      end
    rescue ObjectStorageUnavailableError
      abort "Cannot upload files, make sure the `pseudonimizer.upload.connection` is set properly"
    end

    def cleanup
      return unless File.exist?(@output_dir)

      progress_output.print "Deleting tmp directory #{@output_dir} ... "
      FileUtils.rm_rf(@output_dir)
      progress_output.puts "done"
    rescue
      progress_output.puts "failed"
    end

    private

    attr_reader :progress_output

    def upload_file(file, directory)
      progress_output.print "\t#{file} ... "

      if directory.files.create(key: File.join(@upload_dir, File.basename(file)),
                                body: File.open(file),
                                public: false)
        progress_output.puts "done"
      else
        progress_output.puts "failed"
      end
    end

    def remote_directory
      strong_memoize(:remote_directory) { connect_to_remote_directory }
    end

    def connect_to_remote_directory
      if @connection_params.blank?
        raise ObjectStorageUnavailableError

      end

      connection = ::Fog::Storage.new(@connection_params)

      # We only attempt to create the directory for local backups. For AWS
      # and other cloud providers, we cannot guarantee the user will have
      # permission to create the bucket.
      if connection.service == ::Fog::Storage::Local
        connection.directories.create(key: @remote_dir)
      else
        connection.directories.new(key: @remote_dir)
      end
    end

    def file_list
      Dir[File.join(@output_dir, "*")]
    end
  end
end
