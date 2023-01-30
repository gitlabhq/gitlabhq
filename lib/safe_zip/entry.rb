# frozen_string_literal: true

module SafeZip
  class Entry
    attr_reader :zip_archive, :zip_entry
    attr_reader :path, :params

    def initialize(zip_archive, zip_entry, params)
      @zip_archive = zip_archive
      @zip_entry = zip_entry
      @params = params
      @path = ::File.expand_path(zip_entry.name, params.extract_path)
    end

    def path_dir
      ::File.dirname(path)
    end

    def real_path_dir
      ::File.realpath(path_dir)
    end

    def exist?
      ::File.exist?(path)
    end

    def extract
      # do not extract if file is not part of target directory or target file
      return false unless matching_target_directory || matching_target_file

      # do not overwrite existing file
      raise SafeZip::Extract::AlreadyExistsError, "File already exists #{zip_entry.name}" if exist?

      create_path_dir

      if zip_entry.file?
        extract_file
      elsif zip_entry.directory?
        extract_dir
      elsif zip_entry.symlink?
        extract_symlink
      else
        raise SafeZip::Extract::UnsupportedEntryError, "File #{zip_entry.name} cannot be extracted"
      end
    rescue SafeZip::Extract::Error
      raise
    rescue Zip::EntrySizeError => e
      raise SafeZip::Extract::EntrySizeError, e.message
    rescue StandardError => e
      raise SafeZip::Extract::ExtractError, e.message
    end

    private

    def extract_file
      zip_archive.extract(zip_entry, path)
    end

    def extract_dir
      FileUtils.mkdir(path)
    end

    def extract_symlink
      source_path = read_symlink
      real_source_path = expand_symlink(source_path)

      # ensure that source path of symlink is within target directories
      unless real_source_path.start_with?(matching_target_directory)
        raise SafeZip::Extract::PermissionDeniedError, "Symlink cannot be created targeting: #{source_path}"
      end

      ::File.symlink(source_path, path)
    end

    def create_path_dir
      # Create all directories, but ignore permissions
      FileUtils.mkdir_p(path_dir)

      # disallow to make path dirs to point to another directories
      unless path_dir == real_path_dir
        raise SafeZip::Extract::PermissionDeniedError, "Directory of #{zip_entry.name} points to another directory"
      end
    end

    def matching_target_directory
      params.matching_target_directory(path)
    end

    def matching_target_file
      params.matching_target_file(path)
    end

    def read_symlink
      zip_archive.read(zip_entry)
    end

    def expand_symlink(source_path)
      ::File.realpath(source_path, path_dir)
    rescue StandardError
      raise SafeZip::Extract::SymlinkSourceDoesNotExistError, "Symlink source #{source_path} does not exist"
    end
  end
end
