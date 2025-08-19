# frozen_string_literal: true

module Gitlab
  module DuoAgentPlatform
    class Config
      ConfigError = Class.new(StandardError)

      CONFIG_FILE_NAME = '.gitlab/duo/agent-config.yml'
      CACHE_EXPIRY = 5.minutes

      attr_reader :project

      def initialize(project)
        @project = project
        @config = load_and_cache_config
      end

      def default_image
        return unless valid?

        @config&.dig('image')
      end

      def valid?
        return false unless @config.present? && @config.is_a?(Hash)

        true
      end

      private

      def load_and_cache_config
        Rails.cache.fetch(cache_key, expires_in: CACHE_EXPIRY) do
          load_config
        end
      end

      def load_config
        return {} unless file_content

        YAML.safe_load(file_content)
      rescue Psych::SyntaxError => e
        Gitlab::ErrorTracking.track_exception(e, project_id: project.id)
        {}
      end

      def file_content
        @file_content ||= project.repository.blob_data_at(
          project.default_branch,
          CONFIG_FILE_NAME
        )
      end

      def cache_key
        sha = project.repository.commit(project.default_branch)&.sha || 'empty'
        "duo_config:default_image:#{project.id}:#{sha}"
      end
    end
  end
end
