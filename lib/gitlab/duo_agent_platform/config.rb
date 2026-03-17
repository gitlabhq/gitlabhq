# frozen_string_literal: true

module Gitlab
  module DuoAgentPlatform
    class Config
      ConfigError = Class.new(StandardError)

      CONFIG_FILE_NAME = '.gitlab/duo/agent-config.yml'
      CACHE_EXPIRY = 5.minutes
      MAX_USER_SPECIFIED_DOMAINS = 1000

      attr_reader :project

      def initialize(project)
        @project = project
        @config = load_and_cache_config
      end

      def default_image
        return unless valid?

        @config['image']
      end

      def network_policy
        return unless valid?

        policy = @config['network_policy']
        return unless policy.is_a?(Hash)

        normalized_policy = policy.dup
        normalized_policy['allowed_domains'] =
          Array(policy['allowed_domains']).filter_map do |d|
            d.to_s.downcase.delete("'")
          end.uniq.first(MAX_USER_SPECIFIED_DOMAINS)
        normalized_policy['denied_domains'] =
          Array(policy['denied_domains']).filter_map do |d|
            d.to_s.downcase.delete("'")
          end.uniq.first(MAX_USER_SPECIFIED_DOMAINS)

        normalized_policy
      end

      def setup_script
        return unless valid?

        script = @config['setup_script']
        return unless script

        # Ensure it's an array of strings
        Array(script).map(&:to_s)
      end

      def cache_config
        return unless valid?

        cache = @config['cache']
        return unless cache.is_a?(Hash)

        # Cache must have paths to be valid
        return unless cache['paths'].present?

        # Validate and normalize cache configuration
        normalized_cache = {}

        # Handle cache paths (required)
        normalized_cache['paths'] = Array(cache['paths']).map(&:to_s)

        # Handle cache key configuration (optional)
        if cache['key'].present?
          if cache['key'].is_a?(Hash)
            # Support key with files and optional prefix
            key_config = {}

            # Limits files to 2, ensures strings
            if cache.dig('key', 'files').present?
              files = Array(cache.dig('key', 'files'))
              key_config['files'] = files[0..1].map(&:to_s)
              # Log warning if files were truncated
              if files.size > 2
                Gitlab::AppLogger.warn(message: "Cache key files truncated", original_count: files.size,
                  truncated_count: 2)
              end

              # Optional prefix to combine with SHA (only if files are present)
              key_config['prefix'] = cache.dig('key', 'prefix').to_s if cache.dig('key', 'prefix').present?

              normalized_cache['key'] = key_config
            end
          elsif cache['key'].is_a?(String)
            # Simple string key
            normalized_cache['key'] = cache['key']
          end
        end

        normalized_cache.presence
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
        "duo_config:#{project.id}:#{sha}"
      end
    end
  end
end
