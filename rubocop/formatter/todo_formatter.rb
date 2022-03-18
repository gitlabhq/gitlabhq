# frozen_string_literal: true

require 'set'
require 'rubocop'
require 'yaml'

require_relative '../todo_dir'

module RuboCop
  module Formatter
    # This formatter dumps a YAML configuration file per cop rule
    # into `.rubocop_todo/**/*.yml` which contains detected offenses.
    #
    # For example, this formatter stores offenses for `RSpec/VariableName`
    # in `.rubocop_todo/rspec/variable_name.yml`.
    class TodoFormatter < BaseFormatter
      # Disable a cop which exceeds this limit. This way we ensure that we
      # don't enable a cop by accident when moving it from
      # .rubocop_todo.yml to .rubocop_todo/.
      # We keep the cop disabled if it has been disabled previously explicitly
      # via `Enabled: false` in .rubocop_todo.yml or .rubocop_todo/.
      MAX_OFFENSE_COUNT = 15

      class Todo
        attr_reader :cop_name, :files, :offense_count

        def initialize(cop_name)
          @cop_name = cop_name
          @files = Set.new
          @offense_count = 0
          @cop_class = RuboCop::Cop::Registry.global.find_by_cop_name(cop_name)
        end

        def record(file, offense_count)
          @files << file
          @offense_count += offense_count
        end

        def autocorrectable?
          @cop_class&.support_autocorrect?
        end
      end

      def initialize(output, options = {})
        directory = options.delete(:rubocop_todo_dir) || TodoDir::DEFAULT_TODO_DIR
        @todos = Hash.new { |hash, cop_name| hash[cop_name] = Todo.new(cop_name) }
        @todo_dir = TodoDir.new(directory)
        @config_inspect_todo_dir = load_config_inspect_todo_dir(directory)
        @config_old_todo_yml = load_config_old_todo_yml(directory)
        check_multiple_configurations!

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
          yaml = to_yaml(todo)
          path = @todo_dir.write(todo.cop_name, yaml)

          output.puts "Written to #{relative_path(path)}\n"
        end
      end

      private

      def relative_path(path)
        parent = File.expand_path('..', @todo_dir.directory)
        path.delete_prefix("#{parent}/")
      end

      def to_yaml(todo)
        yaml = []
        yaml << '---'
        yaml << '# Cop supports --auto-correct.' if todo.autocorrectable?
        yaml << "#{todo.cop_name}:"

        if previously_disabled?(todo) && offense_count_exceeded?(todo)
          yaml << "  # Offense count: #{todo.offense_count}"
          yaml << '  # Temporarily disabled due to too many offenses'
          yaml << '  Enabled: false'
        end

        yaml << '  Exclude:'

        files = todo.files.sort.map { |file| "    - '#{file}'" }
        yaml.concat files
        yaml << ''

        yaml.join("\n")
      end

      def offense_count_exceeded?(todo)
        todo.offense_count > MAX_OFFENSE_COUNT
      end

      def check_multiple_configurations!
        cop_names = @config_inspect_todo_dir.keys & @config_old_todo_yml.keys
        return if cop_names.empty?

        list = cop_names.sort.map { |cop_name| "- #{cop_name}" }.join("\n")
        raise "Multiple configurations found for cops:\n#{list}\n"
      end

      def previously_disabled?(todo)
        cop_name = todo.cop_name

        config = @config_old_todo_yml[cop_name] ||
          @config_inspect_todo_dir[cop_name] || {}
        return false if config.empty?

        config['Enabled'] == false
      end

      def load_config_inspect_todo_dir(directory)
        @todo_dir.list_inspect.each_with_object({}) do |path, combined|
          config = YAML.load_file(path)
          combined.update(config) if Hash === config
        end
      end

      # Load YAML configuration from `.rubocop_todo.yml`.
      # We consider this file already old, obsolete, and to be removed soon.
      def load_config_old_todo_yml(directory)
        path = File.expand_path(File.join(directory, '../.rubocop_todo.yml'))
        config = YAML.load_file(path) if File.exist?(path)

        config || {}
      end
    end
  end
end
