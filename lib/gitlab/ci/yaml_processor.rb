# frozen_string_literal: true

# This is the CI Linter component that runs the syntax validations
# while parsing the YAML config into a data structure that is
# then presented to the caller as result object.
# After syntax validations (done by Ci::Config), this component also
# runs logical validation on the built data structure.
module Gitlab
  module Ci
    class YamlProcessor
      ValidationError = Class.new(StandardError)

      def initialize(config_content, opts = {})
        @config_content = config_content
        @opts = opts
      end

      def execute
        if @config_content.blank?
          return Result.new(errors: ['Please provide content of .gitlab-ci.yml'])
        end

        @ci_config = Gitlab::Ci::Config.new(@config_content, **@opts)

        unless @ci_config.valid?
          return Result.new(ci_config: @ci_config, errors: @ci_config.errors, warnings: @ci_config.warnings)
        end

        run_logical_validations!

        Result.new(ci_config: @ci_config, warnings: @ci_config&.warnings)

      rescue Gitlab::Ci::Config::ConfigError => e
        Result.new(ci_config: @ci_config, errors: [e.message], warnings: @ci_config&.warnings)

      rescue ValidationError => e
        Result.new(ci_config: @ci_config, errors: [e.message], warnings: @ci_config&.warnings)
      end

      private

      def run_logical_validations!
        @stages = @ci_config.stages
        @jobs = @ci_config.normalized_jobs

        @jobs.each do |name, job|
          validate_job!(name, job)
        end

        if ::Feature.enabled?(:ci_same_stage_job_needs, @opts[:project], default_enabled: :yaml)
          YamlProcessor::Dag.check_circular_dependencies!(@jobs)
        end
      end

      def validate_job!(name, job)
        validate_job_stage!(name, job)
        validate_job_dependencies!(name, job)
        validate_job_needs!(name, job)
        validate_dynamic_child_pipeline_dependencies!(name, job)
        validate_job_environment!(name, job)
      end

      def validate_job_stage!(name, job)
        return unless job[:stage]

        unless job[:stage].is_a?(String) && job[:stage].in?(@stages)
          error!("#{name} job: chosen stage does not exist; available stages are #{@stages.join(", ")}")
        end
      end

      def validate_job_dependencies!(name, job)
        return unless job[:dependencies]

        job[:dependencies].each do |dependency|
          validate_job_dependency!(name, dependency)
        end
      end

      def validate_dynamic_child_pipeline_dependencies!(name, job)
        return unless includes = job.dig(:trigger, :include)

        Array(includes).each do |included|
          next unless included.is_a?(Hash)
          next unless dependency = included[:job]

          validate_job_dependency!(name, dependency)
        end
      end

      def validate_job_needs!(name, job)
        return unless needs = job.dig(:needs, :job)

        needs.each do |need|
          validate_job_dependency!(name, need[:name], 'need')
        end
      end

      def validate_job_dependency!(name, dependency, dependency_type = 'dependency')
        unless @jobs[dependency.to_sym]
          error!("#{name} job: undefined #{dependency_type}: #{dependency}")
        end

        job_stage_index = stage_index(name)
        dependency_stage_index = stage_index(dependency)

        if ::Feature.enabled?(:ci_same_stage_job_needs, @opts[:project], default_enabled: :yaml)
          unless dependency_stage_index.present? && dependency_stage_index <= job_stage_index
            error!("#{name} job: #{dependency_type} #{dependency} is not defined in current or prior stages")
          end
        else
          # A dependency might be defined later in the configuration
          # with a stage that does not exist
          unless dependency_stage_index.present? && dependency_stage_index < job_stage_index
            error!("#{name} job: #{dependency_type} #{dependency} is not defined in prior stages")
          end
        end
      end

      def stage_index(name)
        stage = @jobs.dig(name.to_sym, :stage)
        @stages.index(stage)
      end

      def validate_job_environment!(name, job)
        return unless job[:environment]
        return unless job[:environment].is_a?(Hash)

        environment = job[:environment]
        validate_on_stop_job!(name, environment, environment[:on_stop])
      end

      def validate_on_stop_job!(name, environment, on_stop)
        return unless on_stop

        on_stop_job = @jobs[on_stop.to_sym]
        unless on_stop_job
          error!("#{name} job: on_stop job #{on_stop} is not defined")
        end

        unless on_stop_job[:environment]
          error!("#{name} job: on_stop job #{on_stop} does not have environment defined")
        end

        unless on_stop_job[:environment][:name] == environment[:name]
          error!("#{name} job: on_stop job #{on_stop} have different environment name")
        end

        unless on_stop_job[:environment][:action] == 'stop'
          error!("#{name} job: on_stop job #{on_stop} needs to have action stop defined")
        end
      end

      def error!(message)
        raise ValidationError, message
      end
    end
  end
end
