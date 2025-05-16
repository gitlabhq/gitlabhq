# frozen_string_literal: true

module CrystalballEnv
  EXCLUDED_PREFIXES = %w[vendor/ruby].freeze

  extend self

  def start!
    return unless ENV['CRYSTALBALL'] == 'true'

    require 'crystalball'

    # Primary strategy currently used for predictive testing
    enable_described_strategy
    # Alternative coverage based strategy currently being evaluated for predictive testing
    # See: https://gitlab.com/groups/gitlab-org/quality/analytics/-/epics/13
    enable_coverage_strategy if ENV['CRYSTALBALL_COVERAGE_STRATEGY'] == 'true'
  end

  def enable_described_strategy
    Crystalball::MapGenerator.start! do |config|
      config.map_storage_path = "crystalball/described/#{map_storage_name}.yml"

      execution_detector = Crystalball::MapGenerator::ObjectSourcesDetector.new(exclude_prefixes: EXCLUDED_PREFIXES)
      config.register Crystalball::MapGenerator::DescribedClassStrategy.new(execution_detector: execution_detector)
    end
  end

  def enable_coverage_strategy
    Crystalball::MapGenerator.start! do |config|
      config.map_storage_path = "crystalball/coverage/#{map_storage_name}.yml"

      config.register Crystalball::MapGenerator::OneshotCoverageStrategy.new(exclude_prefixes: EXCLUDED_PREFIXES)

      # https://toptal.github.io/crystalball/map_generators/#actionviewstrategy
      # require 'crystalball/rails/map_generator/action_view_strategy'
      # config.register Crystalball::Rails::MapGenerator::ActionViewStrategy.new
    end
  end

  def map_storage_name
    (ENV['CI_JOB_NAME'] || 'crystalball_data').gsub(%r{[/ ]}, '_')
  end
end
