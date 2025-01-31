# frozen_string_literal: true

module Gitlab
  module Ci
    # Locates project CI config
    class ProjectConfig
      # The order of sources is important:
      # - EE uses Compliance first since it must be used first if compliance templates are enabled.
      # - Parameter is used by on-demand security scanning which passes the actual CI YAML to use as argument.
      # - Bridge is used for downstream pipelines since the config is defined in the bridge job. If lower in priority,
      #   it would evaluate the project's YAML file instead.
      # - ProjectSetting takes care of CI config coming defined in a project.
      #   This can be the project itself, remote or external.
      # - AutoDevops is used as default option if nothing else is found and if AutoDevops is enabled.
      # - EE uses SecurityPolicyDefault and it should come last. It is only necessary if no other source is available.
      #   Based on the policy configuration different source can be used.
      STANDARD_SOURCES = [
        ProjectConfig::Compliance,
        ProjectConfig::Parameter,
        ProjectConfig::Bridge,
        ProjectConfig::ProjectSetting,
        ProjectConfig::AutoDevops
      ].freeze

      FALLBACK_POLICY_SOURCE = ProjectConfig::SecurityPolicyDefault

      def initialize(
        project:, sha:, custom_content: nil, pipeline_source: nil, pipeline_source_bridge: nil,
        triggered_for_branch: nil, ref: nil, pipeline_policy_context: nil)

        unless pipeline_policy_context&.applying_config_override?
          @config = find_source(project: project,
            sha: sha,
            custom_content: custom_content,
            pipeline_source: pipeline_source,
            pipeline_source_bridge: pipeline_source_bridge,
            triggered_for_branch: triggered_for_branch,
            ref: ref
          )

          return if @config
        end

        fallback_config = FALLBACK_POLICY_SOURCE.new(
          project: project,
          pipeline_source: pipeline_source,
          triggered_for_branch: triggered_for_branch,
          ref: ref,
          pipeline_policy_context: pipeline_policy_context
        )

        @config = fallback_config if fallback_config.exists?
      end

      delegate :content, :source, :url, to: :@config, allow_nil: true
      delegate :internal_include_prepended?, to: :@config

      def exists?
        !!@config&.exists?
      end

      private

      def find_source(
        project:, sha:, custom_content:, pipeline_source:, pipeline_source_bridge:, triggered_for_branch:, ref:)
        STANDARD_SOURCES.each do |source|
          source_config = source.new(project: project,
            sha: sha,
            custom_content: custom_content,
            pipeline_source: pipeline_source,
            pipeline_source_bridge: pipeline_source_bridge,
            triggered_for_branch: triggered_for_branch,
            ref: ref
          )

          return source_config if source_config.exists?
        end

        nil
      end
    end
  end
end

Gitlab::Ci::ProjectConfig.prepend_mod
