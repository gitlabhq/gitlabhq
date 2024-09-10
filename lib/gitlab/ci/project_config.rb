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
      # - EE uses PipelineExecutionPolicyForced and it must come before AutoDevops because
      #   it handles the empty CI config case.
      #   We want to run Pipeline Execution Policies instead of AutoDevops (if they are present).
      # - AutoDevops is used as default option if nothing else is found and if AutoDevops is enabled.
      # - EE uses SecurityPolicyDefault and it should come last. It is only necessary if no other source is available.
      SOURCES = [
        ProjectConfig::Compliance,
        ProjectConfig::Parameter,
        ProjectConfig::Bridge,
        ProjectConfig::ProjectSetting,
        ProjectConfig::PipelineExecutionPolicyForced,
        ProjectConfig::AutoDevops,
        ProjectConfig::SecurityPolicyDefault
      ].freeze

      def initialize(
        project:, sha:, custom_content: nil, pipeline_source: nil, pipeline_source_bridge: nil,
        triggered_for_branch: nil, ref: nil, pipeline_policy_context: nil)
        @config = nil

        sources.each do |source|
          source_config = source.new(project: project,
            sha: sha,
            custom_content: custom_content,
            pipeline_source: pipeline_source,
            pipeline_source_bridge: pipeline_source_bridge,
            triggered_for_branch: triggered_for_branch,
            ref: ref,
            pipeline_policy_context: pipeline_policy_context
          )

          if source_config.exists?
            @config = source_config
            break
          end
        end
      end

      delegate :content, :source, :url, :pipeline_policy_context, to: :@config, allow_nil: true
      delegate :internal_include_prepended?, to: :@config

      def exists?
        !!@config&.exists?
      end

      private

      def sources
        SOURCES
      end
    end
  end
end

Gitlab::Ci::ProjectConfig.prepend_mod
