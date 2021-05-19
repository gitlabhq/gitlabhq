# frozen_string_literal: true

module Pages
  class ZipDirectoryService
    include BaseServiceUtility
    include Gitlab::Utils::StrongMemoize

    # used only to track exceptions in Sentry
    InvalidEntryError = Class.new(StandardError)

    PUBLIC_DIR = 'public'

    attr_reader :public_dir, :real_dir

    def initialize(input_dir, ignore_invalid_entries: false)
      @input_dir = input_dir
      @ignore_invalid_entries = ignore_invalid_entries
    end

    def execute
      return success unless resolve_public_dir

      output_file = File.join(real_dir, "@migrated.zip") # '@' to avoid any name collision with groups or projects

      FileUtils.rm_f(output_file)

      entries_count = 0
      ::Zip::File.open(output_file, ::Zip::File::CREATE) do |zipfile|
        write_entry(zipfile, PUBLIC_DIR)
        entries_count = zipfile.entries.count
      end

      success(archive_path: output_file, entries_count: entries_count)
    rescue StandardError => e
      FileUtils.rm_f(output_file) if output_file
      raise e
    end

    private

    def resolve_public_dir
      @real_dir = File.realpath(@input_dir)
      @public_dir = File.join(real_dir, PUBLIC_DIR)

      valid_path?(public_dir)
    rescue Errno::ENOENT
      false
    end

    def write_entry(zipfile, zipfile_path)
      disk_file_path = File.join(real_dir, zipfile_path)

      unless valid_path?(disk_file_path)
        # archive with invalid entry will just have this entry missing
        raise InvalidEntryError, "#{disk_file_path} is invalid, input_dir: #{@input_dir}"
      end

      ftype = File.lstat(disk_file_path).ftype
      case ftype
      when 'directory'
        recursively_zip_directory(zipfile, disk_file_path, zipfile_path)
      when 'file', 'link'
        zipfile.add(zipfile_path, disk_file_path)
      else
        raise InvalidEntryError, "#{disk_file_path} has invalid ftype: #{ftype}, input_dir: #{@input_dir}"
      end
    rescue Errno::ENOENT, Errno::ELOOP, InvalidEntryError => e
      Gitlab::ErrorTracking.track_exception(e, input_dir: @input_dir, disk_file_path: disk_file_path)

      raise e unless @ignore_invalid_entries
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

    # SafeZip was introduced only recently,
    # so we have invalid entries on disk
    def valid_path?(disk_file_path)
      realpath = File.realpath(disk_file_path)
      realpath == public_dir || realpath.start_with?(public_dir + "/")
    end
  end
end
