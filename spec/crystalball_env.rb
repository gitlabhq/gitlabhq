# frozen_string_literal: true

module CrystalballEnv
  EXCLUDED_PREFIXES = %w[vendor/ruby].freeze

  extend self

  def start!
    return unless ENV['CRYSTALBALL']

    require 'crystalball'
    require_relative '../tooling/lib/tooling/crystalball/coverage_lines_execution_detector'
    require_relative '../tooling/lib/tooling/crystalball/coverage_lines_strategy'

    map_storage_path_base = ENV['CI_JOB_NAME'] || 'crystalball_data'
    map_storage_path = "crystalball/#{map_storage_path_base.gsub(%r{[/ ]}, '_')}.yml"

    execution_detector = Tooling::Crystalball::CoverageLinesExecutionDetector.new(exclude_prefixes: EXCLUDED_PREFIXES)

    Crystalball::MapGenerator.start! do |config|
      config.map_storage_path = map_storage_path
      config.register Tooling::Crystalball::CoverageLinesStrategy.new(execution_detector)
    end
  end
end
