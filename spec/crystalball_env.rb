# frozen_string_literal: true

module CrystalballEnv
  EXCLUDED_PREFIXES = %w[vendor/ruby].freeze

  extend self

  def start!
    return unless ENV['CRYSTALBALL'] == 'true'

    require 'crystalball'
    require_relative '../tooling/lib/tooling/crystalball/described_class_execution_detector'

    map_storage_path_base = ENV['CI_JOB_NAME'] || 'crystalball_data'
    map_storage_path = "crystalball/#{map_storage_path_base.gsub(%r{[/ ]}, '_')}.yml"

    Crystalball::MapGenerator.start! do |config|
      config.map_storage_path = map_storage_path

      # https://toptal.github.io/crystalball/map_generators/#describedclassstrategy
      described_class_execution_detector = Tooling::Crystalball::DescribedClassExecutionDetector.new(
        root_path: File.expand_path('../', __dir__),
        exclude_prefixes: EXCLUDED_PREFIXES
      )
      config.register Crystalball::MapGenerator::DescribedClassStrategy.new(
        execution_detector: described_class_execution_detector
      )

      # Modified version of https://toptal.github.io/crystalball/map_generators/#coveragestrategy
      #
      # require_relative '../tooling/lib/tooling/crystalball/coverage_lines_execution_detector'
      # require_relative '../tooling/lib/tooling/crystalball/coverage_lines_strategy'
      # execution_detector = Tooling::Crystalball::CoverageLinesExecutionDetector.new(
      #   exclude_prefixes: EXCLUDED_PREFIXES
      # )
      # config.register Tooling::Crystalball::CoverageLinesStrategy.new(execution_detector)

      # https://toptal.github.io/crystalball/map_generators/#actionviewstrategy
      # config.register Crystalball::Rails::MapGenerator::ActionViewStrategy.new
    end
  end
end
