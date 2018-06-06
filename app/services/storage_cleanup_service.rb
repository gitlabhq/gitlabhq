class StorageCleanupService
  include Gitlab::Utils::StrongMemoize

  TEMPORARY_FILE_TIMEOUT = 1.day
  TEMPORARY_FILE_PATHS = %w(tmp/cache tmp/uploads).freeze

  attr_reader :config

  delegate :storage_path, :object_store, to: :config
  delegate :enabled, :connection, :remote_directory, prefix: true, to: :object_store

  def initialize(config)
    @config = config
  end

  def execute
    timeout = Time.now - TEMPORARY_FILE_TIMEOUT

    remove_stale_remote_multiparts(timeout)

    TEMPORARY_FILE_PATHS.each do |path|
      remove_stale_remote_files(path, timeout)
      remove_stale_local_files(path, timeout)
      remove_empty_local_directories(path)
    end

    true
  end

  def remove_stale_remote_multiparts(timeout)
    enumerate_all_remote_multipart_uploads do |file_key, upload_id, created|
      next if modified > timeout
      connection.abort_multipart_upload(object_store_remote_directory, file_key, upload_id)
    end
  end

  def remove_stale_remote_files(path, timeout)
    enumerate_all_remote_files(path) do |file_key, modified|
      next if modified > timeout
      connection.delete_object(object_store_remote_directory, file_key)
    end
  end

  def remove_stale_local_files(path, timeout)
    enumerate_all_local_files(path) do |file_path, modified|
      next if modified > timeout
      File.unlink(file_path)
    end
  end

  def remove_empty_local_directories(path)
    enumerate_all_local_directories(path) do |dir_path|
      begin
        Dir.unlink(dir_path)
      rescue SystemCallError
        # catch if directory is non-empty
      end
    end
  end

  private

  def enumerate_all_local_files(prefix, &blk)
    Dir.foreach(File.join(storage_path, prefix)) do |name|
      next if %w(. ..).include?(name)

      path = File.join(storage_path, prefix, name)
      if File.directory?(path)
        enumerate_all_local_files(File.join(prefix, name), &blk)
      elsif File.file?(path)
        yield(path, File.mtime(path))
      end
    end
  end

  def enumerate_all_local_directories(prefix, &blk)
    Dir.foreach(File.join(storage_path, prefix)) do |name|
      next if %w(. ..).include?(name)

      path = File.join(storage_path, prefix, name)
      if File.directory?(path)
        enumerate_all_local_directories(File.join(prefix, name), &blk)
        yield(path)
      end
    end
  end

  def enumerate_all_remote_files(prefix)
    return unless object_store_enabled

    marker = nil

    loop do
      files = connection.get_bucket(object_store_remote_directory,
        { "marker" => marker, "prefix" => prefix }.compact)

      files.body["Contents"].each do |file|
        yield(file["Key"], file["LastModified"])
      end

      break unless files.body["IsTruncated"]
      marker = files.body["Marker"]
      break unless marker
    end
  end

  def enumerate_all_remote_multipart_uploads
    return unless object_store_enabled
    return unless object_store_aws?

    key_marker = nil
    upload_id_marker = nil

    loop do
      uploads = connection.list_multipart_uploads(object_store_remote_directory,
        { "key-marker" => key_marker, "upload-id-marker" => upload_id_marker }.compact)

      uploads.body["Upload"].each do |upload|
        yield(upload["Key"], upload["UploadId"], upload["Initiated"])
      end

      break unless uploads.body["IsTruncated"]
      key_marker = uploads.body["NextKeyMarker"]
      upload_id_marker = uploads.body["NextUploadIdMarker"]
      break unless key_marker && upload_id_marker
    end
  end

  def connection
    @connection ||= ::Fog::Storage.new(object_store_connection.to_hash.deep_symbolize_keys)
  end

  def object_store_aws?
    object_store_connection.provider.to_s == 'AWS'
  end
end
