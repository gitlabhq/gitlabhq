# frozen_string_literal: true

# DEPRECATED. Consider using using Internal Events tracking framework
# https://docs.gitlab.com/ee/development/internal_analytics/internal_event_instrumentation/quick_start.html

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

    VALID_INPUT_DIRS = (TIME_FRAME_DIRS.flat_map { |d| [d.name, d.time_frame] } - %w[none]).freeze

    source_root File.expand_path('../../../generator_templates/usage_metric_definition', __dir__)

    desc '[DEPRECATED] Generates metric definitions yml files'

    class_option :ee, type: :boolean, optional: true, default: false, desc: 'Indicates if metric is for ee'
    class_option :dir,
      type: :string, desc: "Indicates the metric location. It must be one of: #{VALID_INPUT_DIRS.join(', ')}"
    class_option :class_name, type: :string, optional: true, desc: 'Instrumentation class name, e.g.: CountIssues'

    argument :key_paths, type: :array, desc: 'Unique JSON key paths for the metrics'

    def create_metric_file
      say("This generator is DEPRECATED. For event based metrics use Internal Events tracking framework instead.")
      # rubocop: disable Gitlab/DocumentationLinks/HardcodedUrl -- links for developers, not users
      say("https://docs.gitlab.com/ee/development/internal_analytics/internal_event_instrumentation/quick_start.html")

      say("If you need to implement Database, Prometheus or custom metrics, see")
      say("https://docs.gitlab.com/ee/development/internal_analytics/metrics/metrics_instrumentation.html")
      # rubocop: enable Gitlab/DocumentationLinks/HardcodedUrl
      desc = ask("Would you like to continue anyway? y/N") || 'n'
      return unless desc.casecmp('y') == 0

      validate!

      key_paths.each do |key_path|
        template "metric_definition.yml", file_path(key_path), key_path
      end
    end

    def time_frame
      directory&.time_frame
    end

    def value_type
      directory&.value_type
    end

    def tier
      (ee? ? ['#- premium', '- ultimate'] : ['- free', '- premium', '- ultimate']).join("\n")
    end

    def milestone
      Gitlab::VERSION.match('(\d+\.\d+)').captures.first
    end

    def class_name
      options[:class_name]
    end

    private

    def file_path(key_path)
      path = File.join(TOP_LEVEL_DIR, 'metrics', directory&.name, "#{file_name(key_path)}.yml")
      path = File.join(TOP_LEVEL_DIR_EE, path) if ee?
      path
    end

    def validate!
      raise "--dir option is required" unless input_dir.present?
      raise "Invalid dir #{input_dir}, allowed options are #{VALID_INPUT_DIRS.join(', ')}" unless directory.present?

      key_paths.each do |key_path|
        raise "Metric definition with key path '#{key_path}' already exists" if metric_definition_exists?(key_path)
      end
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
    def file_name(key_path)
      "#{Time.now.utc.strftime('%Y%m%d%H%M%S')}_#{metric_name(key_path)}"
    end

    def directory
      @directory ||= TIME_FRAME_DIRS.find { |d| d.match?(input_dir) }
    end

    def metric_name(key_path)
      key_path.split('.').last
    end

    def metric_definitions
      @definitions ||= Gitlab::Usage::MetricDefinition.definitions
    end

    def metric_definition_exists?(key_path)
      metric_definitions[key_path].present?
    end
  end
end
