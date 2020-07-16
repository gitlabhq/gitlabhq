# frozen_string_literal: true

module Gitlab
  module Ci
    class YamlProcessor
      # ValidationError is treated like a result object in the form of an exception.
      # We can return any warnings, raised during the config validation, along with
      # the error object until we support multiple messages to be returned.
      class ValidationError < StandardError
        attr_reader :warnings

        def initialize(message, warnings: [])
          @warnings = warnings
          super(message)
        end
      end

      include Gitlab::Config::Entry::LegacyValidationHelpers

      attr_reader :stages, :jobs

      class Result
        attr_reader :config, :errors, :warnings

        def initialize(config: nil, errors: [], warnings: [])
          @config = config
          @errors = errors
          @warnings = warnings
        end

        def valid?
          config.present? && errors.empty?
        end
      end

      def initialize(config, opts = {})
        @ci_config = Gitlab::Ci::Config.new(config, **opts)
        @config = @ci_config.to_hash

        unless @ci_config.valid?
          error!(@ci_config.errors.first)
        end

        initial_parsing
      rescue Gitlab::Ci::Config::ConfigError => e
        error!(e.message)
      end

      def self.new_with_validation_errors(content, opts = {})
        return Result.new(errors: ['Please provide content of .gitlab-ci.yml']) if content.blank?

        config = Gitlab::Ci::Config.new(content, **opts)
        return Result.new(errors: config.errors, warnings: config.warnings) unless config.valid?

        config = Gitlab::Ci::YamlProcessor.new(content, opts)
        Result.new(config: config, warnings: config.warnings)

      rescue ValidationError => e
        Result.new(errors: [e.message], warnings: e.warnings)

      rescue Gitlab::Ci::Config::ConfigError => e
        Result.new(errors: [e.message])
      end

      def warnings
        @ci_config&.warnings || []
      end

      def builds
        @jobs.map do |name, _|
          build_attributes(name)
        end
      end

      def build_attributes(name)
        job = @jobs.fetch(name.to_sym, {})

        { stage_idx: @stages.index(job[:stage]),
          stage: job[:stage],
          tag_list: job[:tags],
          name: job[:name].to_s,
          allow_failure: job[:ignore],
          when: job[:when] || 'on_success',
          environment: job[:environment_name],
          coverage_regex: job[:coverage],
          yaml_variables: transform_to_yaml_variables(job[:variables]),
          needs_attributes: job.dig(:needs, :job),
          interruptible: job[:interruptible],
          only: job[:only],
          except: job[:except],
          rules: job[:rules],
          cache: job[:cache],
          resource_group_key: job[:resource_group],
          scheduling_type: job[:scheduling_type],
          secrets: job[:secrets],
          options: {
            image: job[:image],
            services: job[:services],
            artifacts: job[:artifacts],
            dependencies: job[:dependencies],
            cross_dependencies: job.dig(:needs, :cross_dependency),
            job_timeout: job[:timeout],
            before_script: job[:before_script],
            script: job[:script],
            after_script: job[:after_script],
            environment: job[:environment],
            retry: job[:retry],
            parallel: job[:parallel],
            instance: job[:instance],
            start_in: job[:start_in],
            trigger: job[:trigger],
            bridge_needs: job.dig(:needs, :bridge)&.first,
            release: release(job)
          }.compact }.compact
      end

      def release(job)
        job[:release] if Gitlab::Ci::Features.release_generation_enabled?
      end

      def stage_builds_attributes(stage)
        @jobs.values
          .select { |job| job[:stage] == stage }
          .map { |job| build_attributes(job[:name]) }
      end

      def stages_attributes
        @stages.uniq.map do |stage|
          seeds = stage_builds_attributes(stage)

          { name: stage, index: @stages.index(stage), builds: seeds }
        end
      end

      def workflow_attributes
        {
          rules: @config.dig(:workflow, :rules),
          yaml_variables: transform_to_yaml_variables(@variables)
        }
      end

      def self.validation_message(content, opts = {})
        return 'Please provide content of .gitlab-ci.yml' if content.blank?

        begin
          Gitlab::Ci::YamlProcessor.new(content, opts)
          nil
        rescue ValidationError => e
          e.message
        end
      end

      private

      def initial_parsing
        ##
        # Global config
        #
        @variables = @ci_config.variables
        @stages = @ci_config.stages

        ##
        # Jobs
        #
        @jobs = Ci::Config::Normalizer.new(@ci_config.jobs).normalize_jobs

        @jobs.each do |name, job|
          # logical validation for job
          validate_job_stage!(name, job)
          validate_job_dependencies!(name, job)
          validate_job_needs!(name, job)
          validate_dynamic_child_pipeline_dependencies!(name, job)
          validate_job_environment!(name, job)
        end
      end

      def transform_to_yaml_variables(variables)
        variables.to_h.map do |key, value|
          { key: key.to_s, value: value, public: true }
        end
      end

      def validate_job_stage!(name, job)
        return unless job[:stage]

        unless job[:stage].is_a?(String) && job[:stage].in?(@stages)
          error!("#{name} job: chosen stage does not exist; available stages are #{@stages.join(", ")}")
        end
      end

      def error!(message)
        raise ValidationError.new(message, warnings: warnings)
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

        # A dependency might be defined later in the configuration
        # with a stage that does not exist
        unless dependency_stage_index.present? && dependency_stage_index < job_stage_index
          error!("#{name} job: #{dependency_type} #{dependency} is not defined in prior stages")
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
    end
  end
end
