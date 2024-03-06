# frozen_string_literal: true

module Gitlab
  module Backup
    module Cli
      module Dependencies
        # Search on PATH or default locations for provided binary and return its fullpath
        #
        # @param [String] binary name
        # @return [String|False] full path to the binary file
        def self.find_executable(binary)
          executable_file = proc { |name| next name if File.file?(name) && File.executable?(name) }

          # Retrieve PATH from ENV or use a fallback
          path = ENV['PATH']&.split(File::PATH_SEPARATOR) || %w[/usr/local/bin /usr/bin /bin]

          # check binary against each PATH
          path.each do |dir|
            file = File.expand_path(binary, dir)

            return file if executable_file.call(file)
          end

          nil
        end

        # Check whether provided binary name exists on PATH or default locations
        #
        # @param [String] binary name
        # @return [Boolean] whether binary exists
        def self.executable_exist?(name)
          !!find_executable(name)
        end
      end
    end
  end
end
