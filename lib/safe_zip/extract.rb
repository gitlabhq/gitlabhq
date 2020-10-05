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

      extract_with_ruby_zip(params)
    end

    private

    def extract_with_ruby_zip(params)
      ::Zip::File.open(archive_path) do |zip_archive|
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
  end
end
