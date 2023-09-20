# frozen_string_literal: true

require 'rails/generators'

module Gitlab
  class UsageMetricGenerator < Rails::Generators::Base
    CE_DIR = 'lib/gitlab/usage/metrics/instrumentations'
    EE_DIR = 'ee/lib/gitlab/usage/metrics/instrumentations'
    SPEC_CE_DIR = 'spec/lib/gitlab/usage/metrics/instrumentations'
    SPEC_EE_DIR = 'ee/spec/lib/gitlab/usage/metrics/instrumentations'

    ALLOWED_SUPERCLASSES = {
      generic: 'Generic',
      database: 'Database',
      redis: 'Redis',
      numbers: 'Numbers'
    }.freeze

    ALLOWED_DATABASE_OPERATIONS = %w[count distinct_count estimate_batch_distinct_count sum average].freeze
    ALLOWED_NUMBERS_OPERATIONS = %w[add].freeze
    ALLOWED_OPERATIONS = ALLOWED_DATABASE_OPERATIONS | ALLOWED_NUMBERS_OPERATIONS

    source_root File.expand_path('usage_metric/templates', __dir__)

    class_option :ee, type: :boolean, optional: true, default: false, desc: 'Indicates if instrumentation is for EE'
    class_option :type, type: :string, desc: "Metric type, must be one of: #{ALLOWED_SUPERCLASSES.keys.join(', ')}"
    class_option :operation, type: :string, desc: "Metric operation, must be one of: #{ALLOWED_OPERATIONS.join(', ')}"

    argument :class_name, type: :string, desc: 'Instrumentation class name, e.g.: CountIssues'

    def create_class_files
      validate!

      template "database_instrumentation_class.rb.template", file_path if type == 'database'
      template "numbers_instrumentation_class.rb.template", file_path if type == 'numbers'
      template "generic_instrumentation_class.rb.template", file_path if type == 'generic'

      template "instrumentation_class_spec.rb.template", spec_file_path
    end

    private

    def validate!
      raise ArgumentError, "Type is required, valid options are #{ALLOWED_SUPERCLASSES.keys.join(', ')}" unless type.present?
      raise ArgumentError, "Unknown type '#{type}', valid options are #{ALLOWED_SUPERCLASSES.keys.join(', ')}" if metric_superclass.nil?
      raise ArgumentError, "Unknown operation '#{operation}' valid operations for database are #{ALLOWED_DATABASE_OPERATIONS.join(', ')}" if type == 'database' && ALLOWED_DATABASE_OPERATIONS.exclude?(operation)
      raise ArgumentError, "Unknown operation '#{operation}' valid operations for numbers are #{ALLOWED_NUMBERS_OPERATIONS.join(', ')}" if type == 'numbers' && ALLOWED_NUMBERS_OPERATIONS.exclude?(operation)
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
