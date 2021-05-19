# frozen_string_literal: true

require 'rails/generators'

module Gitlab
  class UsageMetricDefinitionGenerator < Rails::Generators::Base
    Directory = Struct.new(:name, :time_frame, :value_type) do
      def initialize(...)
        super
        freeze
      end

      def match?(str)
        (name == str || time_frame == str) && str != 'none'
      end
    end

    TIME_FRAME_DIRS = [
      Directory.new('counts_7d',  '7d',   'number'),
      Directory.new('counts_28d', '28d',  'number'),
      Directory.new('counts_all', 'all',  'number'),
      Directory.new('settings',   'none', 'boolean'),
      Directory.new('license',    'none', 'string')
    ].freeze

    TOP_LEVEL_DIR = 'config'
    TOP_LEVEL_DIR_EE = 'ee'

    VALID_INPUT_DIRS = (TIME_FRAME_DIRS.flat_map { |d| [d.name, d.time_frame] } - %w(none)).freeze

    source_root File.expand_path('../../../generator_templates/usage_metric_definition', __dir__)

    desc 'Generates a metric definition yml file'

    class_option :ee, type: :boolean, optional: true, default: false, desc: 'Indicates if metric is for ee'
    class_option :dir,
      type: :string, desc: "Indicates the metric location. It must be one of: #{VALID_INPUT_DIRS.join(', ')}"

    argument :key_path, type: :string, desc: 'Unique JSON key path for the metric'

    def create_metric_file
      validate!

      template "metric_definition.yml", file_path
    end

    def time_frame
      directory&.time_frame
    end

    def value_type
      directory&.value_type
    end

    def distribution
      (ee? ? ['- ee'] : ['- ce', '- ee']).join("\n")
    end

    def tier
      (ee? ? ['#- premium', '- ultimate'] : ['- free', '- premium', '- ultimate']).join("\n")
    end

    def milestone
      Gitlab::VERSION.match('(\d+\.\d+)').captures.first
    end

    private

    def metric_name_suggestion
      "\nname: \"#{Usage::Metrics::NamesSuggestions::Generator.generate(key_path)}\""
    end

    def file_path
      path = File.join(TOP_LEVEL_DIR, 'metrics', directory&.name, "#{file_name}.yml")
      path = File.join(TOP_LEVEL_DIR_EE, path) if ee?
      path
    end

    def validate!
      raise "--dir option is required" unless input_dir.present?
      raise "Invalid dir #{input_dir}, allowed options are #{VALID_INPUT_DIRS.join(', ')}" unless directory.present?
      raise "Metric definition with key path '#{key_path}' already exists" if metric_definition_exists?
    end

    def ee?
      options[:ee]
    end

    def input_dir
      options[:dir]
    end

    # Example of file name
    #
    # 20210201124931_g_project_management_issue_title_changed_weekly.yml
    def file_name
      "#{Time.now.utc.strftime("%Y%m%d%H%M%S")}_#{metric_name}"
    end

    def directory
      @directory ||= TIME_FRAME_DIRS.find { |d| d.match?(input_dir) }
    end

    def metric_name
      key_path.split('.').last
    end

    def metric_definitions
      @definitions ||= Gitlab::Usage::MetricDefinition.definitions(skip_validation: true)
    end

    def metric_definition_exists?
      metric_definitions[key_path].present?
    end
  end
end
