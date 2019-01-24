# frozen_string_literal: true

module SafeZip
  class Extract
    Error = Class.new(StandardError)
    PermissionDeniedError = Class.new(Error)
    SymlinkSourceDoesNotExistError = Class.new(Error)
    UnsupportedEntryError = Class.new(Error)
    AlreadyExistsError = Class.new(Error)
    NoMatchingError = Class.new(Error)
    ExtractError = Class.new(Error)

    attr_reader :archive_path

    def initialize(archive_file)
      @archive_path = archive_file
    end

    def extract(opts = {})
      params = SafeZip::ExtractParams.new(**opts)

      if Feature.enabled?(:safezip_use_rubyzip, default_enabled: true)
        extract_with_ruby_zip(params)
      else
        legacy_unsafe_extract_with_system_zip(params)
      end
    end

    private

    def extract_with_ruby_zip(params)
      Zip::File.open(archive_path) do |zip_archive|
        # Extract all files in the following order:
        # 1. Directories first,
        # 2. Files next,
        # 3. Symlinks last (or anything else)
        extracted = extract_all_entries(zip_archive, params,
          zip_archive.lazy.select(&:directory?))

        extracted += extract_all_entries(zip_archive, params,
          zip_archive.lazy.select(&:file?))

        extracted += extract_all_entries(zip_archive, params,
          zip_archive.lazy.reject(&:directory?).reject(&:file?))

        raise NoMatchingError, 'No entries extracted' unless extracted > 0
      end
    end

    def extract_all_entries(zip_archive, params, entries)
      entries.count do |zip_entry|
        SafeZip::Entry.new(zip_archive, zip_entry, params)
          .extract
      end
    end

    def legacy_unsafe_extract_with_system_zip(params)
      # Requires UnZip at least 6.00 Info-ZIP.
      # -n  never overwrite existing files
      args = %W(unzip -n -qq #{archive_path})

      # We add * to end of directory, because we want to extract directory and all subdirectories
      args += params.directories_wildcard

      # Target directory where we extract
      args += %W(-d #{params.extract_path})

      unless system(*args)
        raise Error, 'archive failed to extract'
      end
    end
  end
end
