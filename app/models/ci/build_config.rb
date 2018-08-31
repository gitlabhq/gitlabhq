module Ci
  class BuildConfig < ActiveRecord::Base
    extend Gitlab::Ci::Model

    self.table_name = 'ci_builds_config'

    belongs_to :build

    serialize :yaml_options # rubocop:disable Cop/ActiveRecordSerialize
    serialize :yaml_variables, Gitlab::Serializer::Ci::Variables # rubocop:disable Cop/ActiveRecordSerialize

    def project
      build.project
    end

    def image
      self.yaml_options[:image] if self.yaml_options
    end

    def cache
      return unless self.yaml_options

      cache = self.yaml_options[:cache]

      if cache && project.jobs_cache_index
        cache = cache.merge(
          key: "#{cache[:key]}-#{project.jobs_cache_index}")
      end

      [cache]
    end

    def before_script
      self.yaml_options[:before_script].to_a if self.yaml_options
    end

    def script
      self.yaml_options[:script].to_a if self.yaml_options
    end

    def after_script
      self.yaml_options[:after_script].to_a if self.yaml_options
    end

    def dependencies
      self.yaml_options[:dependencies] if self.yaml_options
    end

    def environment_action
      self.yaml_options.dig(:environment, :action) if self.yaml_options
    end

    def publishes_artifacts_reports?
      self.yaml_options.dig(:artifacts, :reports)&.any? if self.yaml_options
    end

    def environment_url
      self.yaml_options.dig(:environment, :url) if self.yaml_options
    end

    def retries_max
      self.yaml_options.fetch(:retry, 0).to_i if self.yaml_options
    end
  end
end
