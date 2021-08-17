# frozen_string_literal: true

require 'rails/generators'

module Gitlab
  class UsageMetricGenerator < Rails::Generators::Base
    CE_DIR = 'lib/gitlab/usage/metrics/instrumentations'
    EE_DIR = 'ee/lib/ee/gitlab/usage/metrics/instrumentations'
    SPEC_CE_DIR = 'spec/lib/gitlab/usage/metrics/instrumentations'
    SPEC_EE_DIR = 'ee/spec/lib/ee/gitlab/usage/metrics/instrumentations'

    ALLOWED_SUPERCLASSES = {
      generic: 'Generic',
      database: 'Database',
      redis: 'Redis'
    }.freeze

    ALLOWED_OPERATIONS = %w(count distinct_count estimate_batch_distinct_count).freeze

    source_root File.expand_path('usage_metric/templates', __dir__)

    class_option :ee, type: :boolean, optional: true, default: false, desc: 'Indicates if instrumentation is for EE'
    class_option :type, type: :string, desc: "Metric type, must be one of: #{ALLOWED_SUPERCLASSES.keys.join(', ')}"
    class_option :operation, type: :string, desc: "Metric operation, must be one of: #{ALLOWED_OPERATIONS.join(', ')}"

    argument :class_name, type: :string, desc: 'Instrumentation class name, e.g.: CountIssues'

    def create_class_files
      validate!

      template "database_instrumentation_class.rb.template", file_path if type == 'database'
      template "generic_instrumentation_class.rb.template", file_path if type == 'generic'

      template "instrumentation_class_spec.rb.template", spec_file_path
    end

    private

    def validate!
      raise ArgumentError, "Type is required, valid options are #{ALLOWED_SUPERCLASSES.keys.join(', ')}" unless type.present?
      raise ArgumentError, "Unknown type '#{type}', valid options are #{ALLOWED_SUPERCLASSES.keys.join(', ')}" if metric_superclass.nil?
      raise ArgumentError, "Unknown operation '#{operation}' valid operations are #{ALLOWED_OPERATIONS.join(', ')}" if type == 'database' && !ALLOWED_OPERATIONS.include?(operation)
    end

    def ee?
      options[:ee]
    end

    def type
      options[:type]
    end

    def operation
      options[:operation]
    end

    def file_path
      dir = ee? ? EE_DIR : CE_DIR

      File.join(dir, file_name)
    end

    def spec_file_path
      dir = ee? ? SPEC_EE_DIR : SPEC_CE_DIR

      File.join(dir, spec_file_name)
    end

    def file_name
      "#{class_name.underscore}_metric.rb"
    end

    def spec_file_name
      "#{class_name.underscore}_metric_spec.rb"
    end

    def metric_superclass
      ALLOWED_SUPERCLASSES[type.to_sym]
    end
  end
end
