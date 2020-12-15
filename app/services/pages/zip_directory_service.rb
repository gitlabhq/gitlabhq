# frozen_string_literal: true

module Pages
  class ZipDirectoryService
    InvalidArchiveError = Class.new(RuntimeError)
    InvalidEntryError = Class.new(RuntimeError)

    PUBLIC_DIR = 'public'

    def initialize(input_dir)
      @input_dir = File.realpath(input_dir)
      @output_file = File.join(@input_dir, "@migrated.zip") # '@' to avoid any name collision with groups or projects
    end

    def execute
      FileUtils.rm_f(@output_file)

      count = 0
      ::Zip::File.open(@output_file, ::Zip::File::CREATE) do |zipfile|
        write_entry(zipfile, PUBLIC_DIR)
        count = zipfile.entries.count
      end

      [@output_file, count]
    end

    private

    def write_entry(zipfile, zipfile_path)
      disk_file_path = File.join(@input_dir, zipfile_path)

      unless valid_path?(disk_file_path)
        # archive without public directory is completelly unusable
        raise InvalidArchiveError if zipfile_path == PUBLIC_DIR

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

      realpath == File.join(@input_dir, PUBLIC_DIR) ||
        realpath.start_with?(File.join(@input_dir, PUBLIC_DIR + "/"))
    # happens if target of symlink isn't there
    rescue => e
      Gitlab::ErrorTracking.track_exception(e, input_dir: @input_dir, disk_file_path: disk_file_path)

      false
    end
  end
end
