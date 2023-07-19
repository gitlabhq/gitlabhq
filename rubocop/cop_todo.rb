# frozen_string_literal: true

require_relative 'formatter/graceful_formatter'

module RuboCop
  class CopTodo
    attr_accessor :previously_disabled, :grace_period

    attr_reader :cop_name, :files, :offense_count

    def initialize(cop_name)
      @cop_name = cop_name
      @files = Set.new
      @offense_count = 0
      @cop_class = self.class.find_cop_by_name(cop_name)
      @previously_disabled = false
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
      previously_disabled || grace_period || files.any?
    end

    def to_yaml
      yaml = []
      yaml << '---'
      yaml << '# Cop supports --autocorrect.' if autocorrectable?
      yaml << "#{cop_name}:"

      if previously_disabled
        yaml << "  # Offense count: #{offense_count}"
        yaml << '  # Temporarily disabled due to too many offenses'
        yaml << '  Enabled: false'
      end

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
