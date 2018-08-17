# frozen_string_literal: true

module Ci
  # The purpose of this class is to store Build related configuration that can be disposed.
  # Data that should be persisted forever, should be stored with Ci::Build model.
  class BuildConfig < ActiveRecord::Base
    extend Gitlab::Ci::Model
    include Presentable

    self.table_name = 'ci_builds_metadata'

    belongs_to :build, class_name: 'Ci::Build'
    belongs_to :project

    validates :build, presence: true

    serialize :yaml_commands # rubocop:disable Cop/ActiveRecordSerialize
    serialize :yaml_options # rubocop:disable Cop/ActiveRecordSerialize
    serialize :yaml_variables, Gitlab::Serializer::Ci::Variables # rubocop:disable Cop/ActiveRecordSerialize

    def retries_max
      self.yaml_options.fetch(:retry, 0).to_i
    end

    def environment_action
      self.yaml_options.fetch(:environment, {}).fetch(:action, 'start') if self.yaml_options
    end

    def dependencies
      return [] if empty_dependencies?

      depended_jobs = depends_on_builds

      return depended_jobs unless options[:dependencies].present?

      depended_jobs.select do |job|
        options[:dependencies].include?(job.name)
      end
    end

    def empty_dependencies?
      self.yaml_options[:dependencies]&.empty?
    end
  end

  def has_valid_build_dependencies?
    return true if Feature.enabled?('ci_disable_validates_dependencies')

    dependencies.all?(&:valid_dependency?)
  end

  def valid_dependency?
    return false if artifacts_expired?
    return false if erased?

    true
  end

  def has_environment?
    self.environment.present?
  end

  def environment_url
    self.yaml_options&.dig(:environment, :url) || persisted_environment&.external_url
  end

  def environment
    self.yaml_options&.dig(:environment) || self.yaml_options&.dig(:environment, :name)
  end

  def expanded_environment_name
    return unless has_environment?

    strong_memoize(:expanded_environment_name) do
      ExpandVariables.expand(environment, build.simple_variables)
    end
  end

  def persisted_environment
    return unless has_environment?

    strong_memoize(:persisted_environment) do
      Environment.find_by(name: expanded_environment_name, project: build.project)
    end
  end
end
