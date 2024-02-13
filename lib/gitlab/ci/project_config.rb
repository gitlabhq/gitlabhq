# frozen_string_literal: true

module Gitlab
  module Ci
    # Locates project CI config
    class ProjectConfig
      # The order of sources is important:
      # - EE uses Compliance first since it must be used first if compliance templates are enabled.
      #   (see ee/lib/ee/gitlab/ci/project_config.rb)
      # - Parameter is used by on-demand security scanning which passes the actual CI YAML to use as argument.
      # - Bridge is used for downstream pipelines since the config is defined in the bridge job. If lower in priority,
      #   it would evaluate the project's YAML file instead.
      # - Repository / ExternalProject / Remote: their order is not important between each other.
      # - AutoDevops is used as default option if nothing else is found and if AutoDevops is enabled.
      SOURCES = [
        ProjectConfig::Parameter,
        ProjectConfig::Bridge,
        ProjectConfig::Repository,
        ProjectConfig::ExternalProject,
        ProjectConfig::Remote,
        ProjectConfig::AutoDevops
      ].freeze

      def initialize(
        project:, sha:, custom_content: nil, pipeline_source: nil, pipeline_source_bridge: nil,
        triggered_for_branch: nil)
        @config = find_config(project, sha, custom_content, pipeline_source, pipeline_source_bridge,
          triggered_for_branch)
      end

      delegate :content, :source, :url, to: :@config, allow_nil: true
      delegate :internal_include_prepended?, to: :@config

      def exists?
        !!@config&.exists?
      end

      private

      def find_config(project, sha, custom_content, pipeline_source, pipeline_source_bridge, triggered_for_branch)
        sources.each do |source|
          config = source.new(project, sha, custom_content, pipeline_source, pipeline_source_bridge,
            triggered_for_branch)
          return config if config.exists?
        end

        nil
      end

      def sources
        SOURCES
      end
    end
  end
end

Gitlab::Ci::ProjectConfig.prepend_mod_with('Gitlab::Ci::ProjectConfig')
