# frozen_string_literal: true

require_relative 'formatter/graceful_formatter'

module RuboCop
  class CopTodo
    attr_accessor :grace_period, :header_section

    attr_reader :cop_name, :files, :offense_count

    AUTO_CORRECT_MARKER = '# Cop supports --autocorrect.'

    def initialize(cop_name)
      @cop_name = cop_name
      @files = Set.new
      @offense_count = 0
      @cop_class = self.class.find_cop_by_name(cop_name)
      @grace_period = false
    end

    def record(file, offense_count)
      @files << file
      @offense_count += offense_count
    end

    def add_files(files)
      @files.merge(files)
    end

    def autocorrectable?
      @cop_class&.support_autocorrect?
    end

    def generate?
      grace_period || files.any?
    end

    def to_yaml
      yaml = []
      yaml << '---'
      yaml << AUTO_CORRECT_MARKER if autocorrectable?
      yaml << header_section.sub("#{AUTO_CORRECT_MARKER}\n", '') if header_section && !header_section.empty?
      yaml << "#{cop_name}:"

      yaml << "  #{RuboCop::Formatter::GracefulFormatter.grace_period_key_value}" if grace_period

      if files.any?
        yaml << '  Exclude:'
        yaml.concat files.sort.map { |file| "    - '#{file}'" }
      end

      yaml << ''

      yaml.join("\n")
    end

    def self.find_cop_by_name(cop_name)
      RuboCop::Cop::Registry.global.find_by_cop_name(cop_name)
    end
  end
end
