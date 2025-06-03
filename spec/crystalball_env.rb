# frozen_string_literal: true

module CrystalballEnv
  EXCLUDED_PREFIXES = %w[vendor/ruby].freeze

  extend self

  def start!
    return unless ENV['CRYSTALBALL'] == 'true'

    require 'crystalball'

    # Primary strategy currently used for predictive testing
    enable_described_strategy
    # Coverage based strategy. See: https://gitlab.com/groups/gitlab-org/quality/analytics/-/epics/13
    enable_coverage_strategy if ENV['CRYSTALBALL_COVERAGE_STRATEGY'] == 'true'
  end

  def enable_described_strategy
    Crystalball::MapGenerator.start! do |config|
      config.map_storage_path = "crystalball/described/#{map_storage_name}.yml"

      execution_detector = Crystalball::MapGenerator::ObjectSourcesDetector.new(**excluded_prefixes)
      config.register Crystalball::MapGenerator::DescribedClassStrategy.new(execution_detector: execution_detector)
    end
  end

  def enable_coverage_strategy
    Crystalball::MapGenerator.start! do |config|
      config.map_storage_path = "crystalball/coverage/#{map_storage_name}.yml"
      config.hook_type = :context

      execution_detector = Crystalball::MapGenerator::CoverageStrategy::ExecutionDetector.new(**excluded_prefixes)
      config.register Crystalball::MapGenerator::CoverageStrategy.new(execution_detector: execution_detector)

      # https://gitlab.com/gitlab-org/ruby/gems/crystalball/-/blob/main/docs/map_generators.md?ref_type=heads#actionviewstrategy
      # require 'crystalball/rails/map_generator/action_view_strategy'
      # config.register Crystalball::Rails::MapGenerator::ActionViewStrategy.new
    end
  end

  def excluded_prefixes
    { exclude_prefixes: EXCLUDED_PREFIXES }
  end

  def map_storage_name
    (ENV['CI_JOB_NAME'] || 'crystalball_data').gsub(%r{[/ ]}, '_')
  end
end
