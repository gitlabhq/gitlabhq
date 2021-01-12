# frozen_string_literal: true

module Pages
  class ZipDirectoryService
    include BaseServiceUtility
    include Gitlab::Utils::StrongMemoize

    # used only to track exceptions in Sentry
    InvalidEntryError = Class.new(StandardError)

    PUBLIC_DIR = 'public'

    def initialize(input_dir)
      @input_dir = input_dir
    end

    def execute
      return error("Can not find valid public dir in #{@input_dir}") unless valid_path?(public_dir)

      output_file = File.join(real_dir, "@migrated.zip") # '@' to avoid any name collision with groups or projects

      FileUtils.rm_f(output_file)

      entries_count = 0
      ::Zip::File.open(output_file, ::Zip::File::CREATE) do |zipfile|
        write_entry(zipfile, PUBLIC_DIR)
        entries_count = zipfile.entries.count
      end

      success(archive_path: output_file, entries_count: entries_count)
    rescue => e
      FileUtils.rm_f(output_file) if output_file
      raise e
    end

    private

    def write_entry(zipfile, zipfile_path)
      disk_file_path = File.join(real_dir, zipfile_path)

      unless valid_path?(disk_file_path)
        # archive with invalid entry will just have this entry missing
        raise InvalidEntryError
      end

      case File.lstat(disk_file_path).ftype
      when 'directory'
        recursively_zip_directory(zipfile, disk_file_path, zipfile_path)
      when 'file', 'link'
        zipfile.add(zipfile_path, disk_file_path)
      else
        raise InvalidEntryError
      end
    rescue InvalidEntryError => e
      Gitlab::ErrorTracking.track_exception(e, input_dir: @input_dir, disk_file_path: disk_file_path)
    end

    def recursively_zip_directory(zipfile, disk_file_path, zipfile_path)
      zipfile.mkdir(zipfile_path)

      entries = Dir.entries(disk_file_path) - %w[. ..]
      entries = entries.map { |entry| File.join(zipfile_path, entry) }

      write_entries(zipfile, entries)
    end

    def write_entries(zipfile, entries)
      entries.each do |zipfile_path|
        write_entry(zipfile, zipfile_path)
      end
    end

    # that should never happen, but we want to be safer
    # in theory without this we would allow to use symlinks
    # to pack any directory on disk
    # it isn't possible because SafeZip doesn't extract such archives
    def valid_path?(disk_file_path)
      realpath = File.realpath(disk_file_path)

      realpath == public_dir || realpath.start_with?(public_dir + "/")
    # happens if target of symlink isn't there
    rescue => e
      Gitlab::ErrorTracking.track_exception(e, input_dir: real_dir, disk_file_path: disk_file_path)

      false
    end

    def real_dir
      strong_memoize(:real_dir) do
        File.realpath(@input_dir) rescue nil
      end
    end

    def public_dir
      strong_memoize(:public_dir) do
        File.join(real_dir, PUBLIC_DIR) rescue nil
      end
    end
  end
end
