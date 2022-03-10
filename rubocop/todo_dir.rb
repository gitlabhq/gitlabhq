# frozen_string_literal: true

require 'fileutils'
require 'active_support/inflector/inflections'

module RuboCop
  # Helper class to manage file access to RuboCop TODOs in .rubocop_todo directory.
  class TodoDir
    DEFAULT_TODO_DIR = File.expand_path('../.rubocop_todo', __dir__)

    # Suffix to indicate TODOs being inspected right now.
    SUFFIX_INSPECT = '.inspect'

    attr_reader :directory

    def initialize(directory, inflector: ActiveSupport::Inflector)
      @directory = directory
      @inflector = inflector
    end

    def read(cop_name, suffix = nil)
      read_suffixed(cop_name)
    end

    def write(cop_name, content)
      path = path_for(cop_name)

      FileUtils.mkdir_p(File.dirname(path))
      File.write(path, content)

      path
    end

    def inspect(cop_name)
      path = path_for(cop_name)

      if File.exist?(path)
        FileUtils.mv(path, "#{path}#{SUFFIX_INSPECT}")
        true
      else
        false
      end
    end

    def inspect_all
      pattern = File.join(@directory, '**/*.yml')

      Dir.glob(pattern).count do |path|
        FileUtils.mv(path, "#{path}#{SUFFIX_INSPECT}")
      end
    end

    def list_inspect
      pattern = File.join(@directory, "**/*.yml.inspect")

      Dir.glob(pattern)
    end

    def delete_inspected
      pattern = File.join(@directory, '**/*.yml.inspect')

      Dir.glob(pattern).count do |path|
        File.delete(path)
      end
    end

    private

    def read_suffixed(cop_name, suffix = nil)
      path = path_for(cop_name, suffix)

      File.read(path) if File.exist?(path)
    end

    def path_for(cop_name, suffix = nil)
      todo_path = "#{@inflector.underscore(cop_name)}.yml#{suffix}"

      File.join(@directory, todo_path)
    end
  end
end
