#!/usr/bin/env ruby
# frozen_string_literal: true

require 'fileutils'
require 'readline'
require 'active_support'
require 'active_support/core_ext/string'

module GitLab
  module MigrationTools
    class BaseMigrationCreator
      attr_reader :options

      def initialize
        @options = create_options_struct.new
      end

      def execute
        collect_input
        write
        display_success_message
        display_additional_info
      end

      protected

      def create_options_struct
        raise NotImplementedError
      end

      def collect_input
        raise NotImplementedError
      end

      def file_path
        raise NotImplementedError, "Subclasses must implement #file_path"
      end

      def file_contents
        raise NotImplementedError, "Subclasses must implement #file_contents"
      end

      def spec_file_path
        raise NotImplementedError, "Subclasses must implement #spec_file_path"
      end

      def spec_contents
        raise NotImplementedError, "Subclasses must implement #spec_contents"
      end

      def timestamp
        @timestamp ||= Time.now.strftime('%Y%m%d%H%M%S')
      end

      def file_name
        @file_name ||= "#{timestamp}_#{options.name.dup.underscore}"
      end

      def write
        write_file(file_path, file_contents)
        write_file(spec_file_path, spec_contents)
      end

      def display_success_message
        $stdout.puts "\e[32mcreated\e[0m #{file_path}"
        $stdout.puts "\e[32mcreated\e[0m #{spec_file_path}"
      end

      def display_additional_info; end

      def read_name
        read_variable('name', 'Name of the migration in CamelCase')
      end

      def read_url(description)
        $stdout.puts "\n>> #{description} (enter to skip):"

        loop do
          url = Readline.readline('?> ', false)&.strip
          url = nil if url.empty?
          return url if url.nil? || url.start_with?('https://')

          warn 'Error: URL needs to start with https://'
        end
      end

      def current_milestone
        milestone = File.read('VERSION')
        milestone.gsub(/^(\d+\.\d+).*$/, '\1').chomp
      end

      def read_variable(name, description, optional: false)
        $stdout.puts "\n>> #{description}:"

        loop do
          variable = Readline.readline('?> ', false)&.strip
          return variable if !variable.empty? || optional

          warn "Error: #{name} is required."
        end
      end

      def write_file(path, contents)
        FileUtils.mkdir_p(File.dirname(path))
        File.write(path, contents)
      end
    end
  end
end
