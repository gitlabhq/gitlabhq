# frozen_string_literal: true

require 'rubocop'
require 'yaml'

require_relative '../todo_dir'
require_relative '../cop_todo'
require_relative '../formatter/graceful_formatter'

module RuboCop
  module Formatter
    # This formatter dumps a YAML configuration file per cop rule
    # into `.rubocop_todo/**/*.yml` which contains detected offenses.
    #
    # For example, this formatter stores offenses for `RSpec/VariableName`
    # in `.rubocop_todo/rspec/variable_name.yml`.
    class TodoFormatter < BaseFormatter
      DEFAULT_BASE_DIRECTORY = File.expand_path('../../.rubocop_todo', __dir__)

      # Make sure that HAML exclusions are retained.
      # This allows enabling cop rules in haml-lint and only exclude HAML files
      # with offenses.
      #
      # See https://gitlab.com/gitlab-org/gitlab/-/issues/415330#caveats
      RETAIN_EXCLUSIONS = %r{\.haml$}

      class << self
        attr_accessor :base_directory
      end

      self.base_directory = DEFAULT_BASE_DIRECTORY

      def initialize(output, _options = {})
        @directory = self.class.base_directory
        @todos = Hash.new { |hash, cop_name| hash[cop_name] = CopTodo.new(cop_name) }
        @todo_dir = TodoDir.new(directory)
        @config_inspect_todo_dir = load_config_inspect_todo_dir
        @config_old_todo_yml = load_config_old_todo_yml
        check_multiple_configurations!
        create_todos_retaining_exclusions(@config_inspect_todo_dir)

        super
      end

      def file_finished(file, offenses)
        return if offenses.empty?

        file = relative_path(file)

        offenses.map(&:cop_name).tally.each do |cop_name, offense_count|
          @todos[cop_name].record(file, offense_count)
        end
      end

      def finished(_inspected_files)
        @todos.values.sort_by(&:cop_name).each do |todo|
          next unless configure_and_validate_todo(todo)

          path = @todo_dir.write(todo.cop_name, todo.to_yaml)
          output.puts "Written to #{relative_path(path)}\n"
        end
      end

      def self.with_base_directory(directory)
        old = base_directory
        self.base_directory = directory

        yield
      ensure
        self.base_directory = old
      end

      private

      attr_reader :directory

      def relative_path(path)
        parent = File.expand_path('..', directory)
        path.delete_prefix("#{parent}/")
      end

      def check_multiple_configurations!
        cop_names = @config_inspect_todo_dir.keys & @config_old_todo_yml.keys
        return if cop_names.empty?

        list = cop_names.sort.map { |cop_name| "- #{cop_name}" }.join("\n")
        raise "Multiple configurations found for cops:\n#{list}\n"
      end

      def create_todos_retaining_exclusions(inspected_cop_config)
        inspected_cop_config.each do |cop_name, config|
          todo = @todos[cop_name]
          excluded_files = config['Exclude'] || []
          todo.add_files(excluded_files.grep(RETAIN_EXCLUSIONS))
        end
      end

      def config_for(todo)
        cop_name = todo.cop_name

        @config_old_todo_yml[cop_name] || @config_inspect_todo_dir[cop_name] || {}
      end

      def previously_disabled?(todo)
        config = config_for(todo)
        return false if config.empty?

        config['Enabled'] == false
      end

      def grace_period?(todo)
        config = config_for(todo)

        GracefulFormatter.grace_period?(todo.cop_name, config)
      end

      def configure_and_validate_todo(todo)
        todo.previously_disabled = previously_disabled?(todo)
        todo.grace_period = grace_period?(todo)

        if todo.previously_disabled && todo.grace_period
          raise "#{todo.cop_name}: Cop must be enabled to use `#{GracefulFormatter.grace_period_key_value}`."
        end

        todo.generate?
      end

      def load_config_inspect_todo_dir
        @todo_dir.list_inspect.each_with_object({}) do |path, combined|
          config = YAML.load_file(path)
          combined.update(config) if Hash === config
        end
      end

      # Load YAML configuration from `.rubocop_todo.yml`.
      # We consider this file already old, obsolete, and to be removed soon.
      def load_config_old_todo_yml
        path = File.expand_path(File.join(directory, '../.rubocop_todo.yml'))
        config = YAML.load_file(path) if File.exist?(path)

        config || {}
      end
    end
  end
end
