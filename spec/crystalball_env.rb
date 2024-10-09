# frozen_string_literal: true

module CrystalballEnv
  EXCLUDED_PREFIXES = %w[vendor/ruby].freeze

  extend self

  def start!
    return unless ENV['CRYSTALBALL'] == 'true'

    require 'crystalball'

    enable_described_strategy # We use this for writing and reading

    # TODO: Please work on https://gitlab.com/gitlab-org/gitlab/-/issues/498479 before enabling CoverageStrategy again
    # enable_coverage_strategy # We use this only for writing for now
  end

  def enable_described_strategy
    require_relative '../tooling/lib/tooling/crystalball/described_class_execution_detector'

    Crystalball::MapGenerator.start! do |config|
      config.map_storage_path = "crystalball/described/#{map_storage_name}.yml"

      # https://toptal.github.io/crystalball/map_generators/#describedclassstrategy
      described_class_execution_detector = Tooling::Crystalball::DescribedClassExecutionDetector.new(
        root_path: File.expand_path('../', __dir__),
        exclude_prefixes: EXCLUDED_PREFIXES
      )
      config.register Crystalball::MapGenerator::DescribedClassStrategy.new(
        execution_detector: described_class_execution_detector
      )
    end
  end

  def enable_coverage_strategy
    # Modified version of https://toptal.github.io/crystalball/map_generators/#coveragestrategy
    require_relative '../tooling/lib/tooling/crystalball/coverage_lines_execution_detector'
    require_relative '../tooling/lib/tooling/crystalball/coverage_lines_strategy'

    Crystalball::MapGenerator.start! do |config|
      config.map_storage_path = "crystalball/coverage/#{map_storage_name}.yml"

      execution_detector = Tooling::Crystalball::CoverageLinesExecutionDetector
        .new(exclude_prefixes: EXCLUDED_PREFIXES)

      config.register Tooling::Crystalball::CoverageLinesStrategy
        .new(execution_detector)

      # https://toptal.github.io/crystalball/map_generators/#actionviewstrategy
      # require 'crystalball/rails/map_generator/action_view_strategy'
      # config.register Crystalball::Rails::MapGenerator::ActionViewStrategy.new
    end
  end

  def map_storage_name
    (ENV['CI_JOB_NAME'] || 'crystalball_data').gsub(%r{[/ ]}, '_')
  end
end
