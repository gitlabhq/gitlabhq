# frozen_string_literal: true

module SafeZip
  class ExtractParams
    include Gitlab::Utils::StrongMemoize

    attr_reader :directories, :extract_path

    def initialize(directories:, to:)
      @directories = directories
      @extract_path = ::File.realpath(to)
    end

    def matching_target_directory(path)
      target_directories.find do |directory|
        path.start_with?(directory)
      end
    end

    def target_directories
      strong_memoize(:target_directories) do
        directories.map do |directory|
          ::File.join(::File.expand_path(directory, extract_path), '')
        end
      end
    end

    def directories_wildcard
      strong_memoize(:directories_wildcard) do
        directories.map do |directory|
          ::File.join(directory, '*')
        end
      end
    end
  end
end
