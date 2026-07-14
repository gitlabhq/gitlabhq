# frozen_string_literal: true

module SafeZip
  class ExtractParams
    attr_reader :directories, :files, :extract_path

    def initialize(to:, directories: [], files: [])
      @directories = directories
      @files = files
      @extract_path = ::File.realpath(to)
      validate!
    end

    def matching_target_directory(path)
      target_directories.find do |directory|
        path.start_with?(directory)
      end
    end

    def target_directories
      @target_directories ||= directories.map do |directory|
        ::File.join(::File.expand_path(directory, extract_path), '')
      end
    end

    def directories_wildcard
      @directories_wildcard ||= directories.map do |directory|
        ::File.join(directory, '*')
      end
    end

    def matching_target_file(path)
      target_files.include?(path)
    end

    private

    def target_files
      @target_files ||= files.map do |file|
        ::File.join(extract_path, file)
      end
    end

    def validate!
      raise ArgumentError, 'Either directories or files are required' if directories.empty? && files.empty?
    end
  end
end
