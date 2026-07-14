# frozen_string_literal: true

module SafeZip
  # SafeZip::Extract provides a safe interface
  # to extract specific directories or files within a `zip` archive.
  #
  # @example Extract directories to destination
  #   SafeZip::Extract.new(archive_file).extract(directories: ['app/', 'test/'], to: destination_path)
  # @example Extract files to destination
  #   SafeZip::Extract.new(archive_file).extract(files: ['index.html', 'app/index.js'], to: destination_path)
  class Extract
    Error = Class.new(StandardError)
    PermissionDeniedError = Class.new(Error)
    SymlinkSourceDoesNotExistError = Class.new(Error)
    UnsupportedEntryError = Class.new(Error)
    EntrySizeError = Class.new(Error)
    AlreadyExistsError = Class.new(Error)
    NoMatchingError = Class.new(Error)
    ExtractError = Class.new(Error)

    attr_reader :archive_path

    def initialize(archive_file)
      @archive_path = archive_file
    end

    # extract given files or directories from the archive into the destination path
    #
    # @param [Hash] opts the options for extraction.
    # @option opts [Array<String] :files list of files to be extracted
    # @option opts [Array<String] :directories list of directories to be extracted
    # @option opts [String] :to destination path
    #
    # @raise [PermissionDeniedError]
    # @raise [SymlinkSourceDoesNotExistError]
    # @raise [UnsupportedEntryError]
    # @raise [EntrySizeError]
    # @raise [AlreadyExistsError]
    # @raise [NoMatchingError]
    # @raise [ExtractError]
    def extract(opts = {})
      params = SafeZip::ExtractParams.new(**opts)

      extract_with_ruby_zip(params)
    end

    private

    def extract_with_ruby_zip(params)
      ::Zip::File.open(archive_path) do |zip_archive| # rubocop:disable Performance/Rubyzip
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
