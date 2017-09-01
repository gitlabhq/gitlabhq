module Ci
  class GitlabCiYamlProcessor
    ValidationError = Class.new(StandardError)

    include Gitlab::Ci::Config::Entry::LegacyValidationHelpers

    attr_reader :path, :cache, :stages, :jobs

    def initialize(config, path = nil)
      @ci_config = Gitlab::Ci::Config.new(config)
      @config = @ci_config.to_hash
      @path = path

      unless @ci_config.valid?
        raise ValidationError, @ci_config.errors.first
      end

      initial_parsing
    rescue Gitlab::Ci::Config::Loader::FormatError => e
      raise ValidationError, e.message
    end

    def builds_for_stage_and_ref(stage, ref, tag = false, source = nil)
      jobs_for_stage_and_ref(stage, ref, tag, source).map do |name, _|
        build_attributes(name)
      end
    end

    def builds
      @jobs.map do |name, _|
        build_attributes(name)
      end
    end

    def stage_seeds(pipeline)
      seeds = @stages.uniq.map do |stage|
        builds = pipeline_stage_builds(stage, pipeline)

        Gitlab::Ci::Stage::Seed.new(pipeline, stage, builds) if builds.any?
      end

      seeds.compact
    end

    def build_attributes(name)
      job = @jobs[name.to_sym] || {}

      { stage_idx: @stages.index(job[:stage]),
        stage: job[:stage],
        commands: job[:commands],
        tag_list: job[:tags] || [],
        name: job[:name].to_s,
        allow_failure: job[:ignore],
        when: job[:when] || 'on_success',
        environment: job[:environment_name],
        coverage_regex: job[:coverage],
        yaml_variables: yaml_variables(name),
        options: {
          image: job[:image],
          services: job[:services],
          artifacts: job[:artifacts],
          cache: job[:cache],
          dependencies: job[:dependencies],
          before_script: job[:before_script],
          script: job[:script],
          after_script: job[:after_script],
          environment: job[:environment],
          retry: job[:retry]
        }.compact }
    end

    def self.validation_message(content)
      return 'Please provide content of .gitlab-ci.yml' if content.blank?

      begin
        Ci::GitlabCiYamlProcessor.new(content)
        nil
      rescue ValidationError, Psych::SyntaxError => e
        e.message
      end
    end

    private

    def pipeline_stage_builds(stage, pipeline)
      builds = builds_for_stage_and_ref(
        stage, pipeline.ref, pipeline.tag?, pipeline.source)

      builds.select do |build|
        job = @jobs[build.fetch(:name).to_sym]
        has_kubernetes = pipeline.has_kubernetes_active?
        only_kubernetes = job.dig(:only, :kubernetes)
        except_kubernetes = job.dig(:except, :kubernetes)

        [!only_kubernetes && !except_kubernetes,
         only_kubernetes && has_kubernetes,
         except_kubernetes && !has_kubernetes].any?
      end
    end

    def jobs_for_ref(ref, tag = false, source = nil)
      @jobs.select do |_, job|
        process?(job.dig(:only, :refs), job.dig(:except, :refs), ref, tag, source)
      end
    end

    def jobs_for_stage_and_ref(stage, ref, tag = false, source = nil)
      jobs_for_ref(ref, tag, source).select do |_, job|
        job[:stage] == stage
      end
    end

    def initial_parsing
      ##
      # Global config
      #
      @before_script = @ci_config.before_script
      @image = @ci_config.image
      @after_script = @ci_config.after_script
      @services = @ci_config.services
      @variables = @ci_config.variables
      @stages = @ci_config.stages
      @cache = @ci_config.cache

      ##
      # Jobs
      #
      @jobs = @ci_config.jobs

      @jobs.each do |name, job|
        # logical validation for job

        validate_job_stage!(name, job)
        validate_job_dependencies!(name, job)
        validate_job_environment!(name, job)
      end
    end

    def yaml_variables(name)
      variables = (@variables || {})
        .merge(job_variables(name))

      variables.map do |key, value|
        { key: key.to_s, value: value, public: true }
      end
    end

    def job_variables(name)
      job = @jobs[name.to_sym]
      return {} unless job

      job[:variables] || {}
    end

    def validate_job_stage!(name, job)
      return unless job[:stage]

      unless job[:stage].is_a?(String) && job[:stage].in?(@stages)
        raise ValidationError, "#{name} job: stage parameter should be #{@stages.join(", ")}"
      end
    end

    def validate_job_dependencies!(name, job)
      return unless job[:dependencies]

      stage_index = @stages.index(job[:stage])

      job[:dependencies].each do |dependency|
        raise ValidationError, "#{name} job: undefined dependency: #{dependency}" unless @jobs[dependency.to_sym]

        unless @stages.index(@jobs[dependency.to_sym][:stage]) < stage_index
          raise ValidationError, "#{name} job: dependency #{dependency} is not defined in prior stages"
        end
      end
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
        raise ValidationError, "#{name} job: on_stop job #{on_stop} is not defined"
      end

      unless on_stop_job[:environment]
        raise ValidationError, "#{name} job: on_stop job #{on_stop} does not have environment defined"
      end

      unless on_stop_job[:environment][:name] == environment[:name]
        raise ValidationError, "#{name} job: on_stop job #{on_stop} have different environment name"
      end

      unless on_stop_job[:environment][:action] == 'stop'
        raise ValidationError, "#{name} job: on_stop job #{on_stop} needs to have action stop defined"
      end
    end

    def process?(only_params, except_params, ref, tag, source)
      if only_params.present?
        return false unless matching?(only_params, ref, tag, source)
      end

      if except_params.present?
        return false if matching?(except_params, ref, tag, source)
      end

      true
    end

    def matching?(patterns, ref, tag, source)
      patterns.any? do |pattern|
        pattern, path = pattern.split('@', 2)
        matches_path?(path) && matches_pattern?(pattern, ref, tag, source)
      end
    end

    def matches_path?(path)
      return true unless path

      path == self.path
    end

    def matches_pattern?(pattern, ref, tag, source)
      return true if tag && pattern == 'tags'
      return true if !tag && pattern == 'branches'
      return true if source_to_pattern(source) == pattern

      if pattern.first == "/" && pattern.last == "/"
        Regexp.new(pattern[1...-1]) =~ ref
      else
        pattern == ref
      end
    end

    def source_to_pattern(source)
      if %w[api external web].include?(source)
        source
      else
        source&.pluralize
      end
    end
  end
end
