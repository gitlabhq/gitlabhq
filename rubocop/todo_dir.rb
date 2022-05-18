# frozen_string_literal: true

require 'fileutils'
require 'active_support/inflector/inflections'

module RuboCop
  # Helper class to manage file access to RuboCop TODOs in .rubocop_todo directory.
  class TodoDir
    # Suffix a TODO file.
    SUFFIX_YAML = '.yml'

    # Suffix to indicate TODOs being inspected right now.
    SUFFIX_INSPECT = '.inspect'

    # Instantiates a TodoDir.
    #
    # @param directory [String] base directory where all TODO YAML files are written to.
    # @param inflector [ActiveSupport::Inflector, #underscore] an object which supports
    #                  converting a string to its underscored version.
    def initialize(directory, inflector: ActiveSupport::Inflector)
      @directory = directory
      @inflector = inflector
    end

    # Reads content of TODO YAML for given +cop_name+.
    #
    # @param cop_name [String] name of the cop rule
    #
    # @return [String, nil] content of the TODO YAML file if it exists
    def read(cop_name)
      path = path_for(cop_name)

      File.read(path) if File.exist?(path)
    end

    # Saves +content+ for given +cop_name+ to TODO YAML file.
    #
    # @return [String] path of the written TODO YAML file
    def write(cop_name, content)
      path = path_for(cop_name)

      FileUtils.mkdir_p(File.dirname(path))
      File.write(path, content)

      path
    end

    # Marks a TODO YAML file for inspection by renaming the original TODO YAML
    # and appending the suffix +.inspect+ to it.
    #
    # @return [Boolean] +true+ a file was marked for inspection successfully.
    def inspect(cop_name)
      path = path_for(cop_name)

      if File.exist?(path)
        FileUtils.mv(path, "#{path}#{SUFFIX_INSPECT}")
        true
      else
        false
      end
    end

    # Marks all TODO YAML files for inspection.
    #
    # @return [Integer] number of renamed YAML TODO files.
    #
    # @see inspect
    def inspect_all
      pattern = File.join(@directory, "**/*#{SUFFIX_YAML}")

      Dir.glob(pattern).count do |path|
        FileUtils.mv(path, "#{path}#{SUFFIX_INSPECT}")
      end
    end

    # Returns a list of TODO YAML files which are marked for inspection.
    #
    # @return [Array<String>] list of paths
    #
    # @see inspect
    # @see inspect_all
    def list_inspect
      pattern = File.join(@directory, "**/*#{SUFFIX_YAML}#{SUFFIX_INSPECT}")

      Dir.glob(pattern)
    end

    # Deletes a list of TODO yaml files which were marked for inspection.
    #
    # @return [Integer] number of deleted YAML TODO files.
    #
    # @see #inspect
    # @see #inspect_all
    def delete_inspected
      list_inspect.count do |path|
        File.delete(path)
      end
    end

    private

    def path_for(cop_name)
      todo_path = "#{@inflector.underscore(cop_name)}#{SUFFIX_YAML}"

      File.join(@directory, todo_path)
    end
  end
end
