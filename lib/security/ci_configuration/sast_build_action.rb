# frozen_string_literal: true

module Security
  module CiConfiguration
    class SastBuildAction < BaseBuildAction
      def initialize(auto_devops_enabled, params, existing_gitlab_ci_content, ci_config_path = ::Ci::Pipeline::DEFAULT_CONFIG_PATH)
        super(auto_devops_enabled, existing_gitlab_ci_content, ci_config_path)
        @variables = variables(params)
        @default_sast_values = default_sast_values(params)
        @default_values_overwritten = false
      end

      private

      def variables(params)
        collect_values(params, :value)
      end

      def default_sast_values(params)
        collect_values(params, :default_value)
      end

      def collect_values(config, key)
        global_variables = config[:global].to_h { |k| [k[:field], k[key]] }
        pipeline_variables = config[:pipeline].to_h { |k| [k[:field], k[key]] }

        analyzer_variables = collect_analyzer_values(config, key)

        global_variables.merge!(pipeline_variables).merge!(analyzer_variables)
      end

      def collect_analyzer_values(config, key)
        analyzer_variables = analyzer_variables_for(config, key)
        analyzer_variables['SAST_EXCLUDED_ANALYZERS'] = if key == :value
                                                          config[:analyzers]
                                                          &.reject { |a| a[:enabled] }
                                                          &.collect { |a| a[:name] }
                                                          &.sort
                                                          &.join(', ')
                                                        else
                                                          ''
                                                        end

        analyzer_variables
      end

      def analyzer_variables_for(config, key)
        config[:analyzers]
          &.select { |a| a[:enabled] && a[:variables] }
          &.flat_map { |a| a[:variables] }
          &.collect { |v| [v[:field], v[key]] }.to_h
      end

      def update_existing_content!
        @existing_gitlab_ci_content['stages'] = set_stages
        @existing_gitlab_ci_content['variables'] = set_variables(global_variables, @existing_gitlab_ci_content)
        @existing_gitlab_ci_content['sast'] = set_sast_block
        @existing_gitlab_ci_content['include'] = generate_includes

        @existing_gitlab_ci_content.select! { |k, v| v.present? }
        @existing_gitlab_ci_content['sast'].select! { |k, v| v.present? }
      end

      def set_stages
        existing_stages = @existing_gitlab_ci_content['stages'] || []
        base_stages = @auto_devops_enabled ? auto_devops_stages : ['test']
        (existing_stages + base_stages + [sast_stage]).uniq
      end

      def auto_devops_stages
        auto_devops_template = YAML.safe_load(Gitlab::Template::GitlabCiYmlTemplate.find('Auto-DevOps').content)
        auto_devops_template['stages']
      end

      def sast_stage
        @variables['stage'].presence ? @variables['stage'] : 'test'
      end

      def set_variables(variables, hash_to_update = {})
        hash_to_update['variables'] ||= {}

        variables.each do |key|
          if @variables[key].present? && @variables[key].to_s != @default_sast_values[key].to_s
            hash_to_update['variables'][key] = @variables[key]
            @default_values_overwritten = true
          else
            hash_to_update['variables'].delete(key)
          end
        end

        hash_to_update['variables']
      end

      def set_sast_block
        sast_content = @existing_gitlab_ci_content['sast'] || {}
        sast_content['variables'] = set_variables(sast_variables)
        sast_content['stage'] = sast_stage
        sast_content.select { |k, v| v.present? }
      end

      def template
        return 'Auto-DevOps.gitlab-ci.yml' if @auto_devops_enabled

        'Security/SAST.gitlab-ci.yml'
      end

      def global_variables
        %w[
          SECURE_ANALYZERS_PREFIX
        ]
      end

      def sast_variables
        %w[
          SAST_EXCLUDED_PATHS
          SEARCH_MAX_DEPTH
          SAST_EXCLUDED_ANALYZERS
          SAST_BRAKEMAN_LEVEL
          SAST_BANDIT_EXCLUDED_PATHS
          SAST_FLAWFINDER_LEVEL
          SAST_GOSEC_LEVEL
        ]
      end
    end
  end
end
