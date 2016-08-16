module Ci
  class GitlabCiYamlProcessor
    class ValidationError < StandardError; end

    include Gitlab::Ci::Config::Node::LegacyValidationHelpers

    attr_reader :path, :cache, :stages

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

    def jobs_for_ref(ref, tag = false, trigger_request = nil)
      @jobs.select do |_, job|
        process?(job[:only], job[:except], ref, tag, trigger_request)
      end
    end

    def jobs_for_stage_and_ref(stage, ref, tag = false, trigger_request = nil)
      jobs_for_ref(ref, tag, trigger_request).select do |_, job|
        job[:stage] == stage
      end
    end

    def builds_for_ref(ref, tag = false, trigger_request = nil)
      jobs_for_ref(ref, tag, trigger_request).map do |name, _|
        build_attributes(name)
      end
    end

    def builds_for_stage_and_ref(stage, ref, tag = false, trigger_request = nil)
      jobs_for_stage_and_ref(stage, ref, tag, trigger_request).map do |name, _|
        build_attributes(name)
      end
    end

    def builds
      @jobs.map do |name, _|
        build_attributes(name)
      end
    end

    def build_attributes(name)
      job = @jobs[name.to_sym] || {}
      {
        stage_idx: @stages.index(job[:stage]),
        stage: job[:stage],
        ##
        # Refactoring note:
        #  - before script behaves differently than after script
        #  - after script returns an array of commands
        #  - before script should be a concatenated command
        commands: [job[:before_script] || @before_script, job[:script]].flatten.compact.join("\n"),
        tag_list: job[:tags] || [],
        name: job[:name].to_s,
        allow_failure: job[:allow_failure] || false,
        when: job[:when] || 'on_success',
        environment: job[:environment],
        yaml_variables: yaml_variables(name),
        options: {
          image: job[:image] || @image,
          services: job[:services] || @services,
          artifacts: job[:artifacts],
          cache: job[:cache] || @cache,
          dependencies: job[:dependencies],
          after_script: job[:after_script] || @after_script,
        }.compact
      }
    end

    private

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
      end
    end

    def yaml_variables(name)
      variables = (@variables || {})
        .merge(job_variables(name))

      variables.map do |key, value|
        { key: key, value: value, public: true }
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

    def process?(only_params, except_params, ref, tag, trigger_request)
      if only_params.present?
        return false unless matching?(only_params, ref, tag, trigger_request)
      end

      if except_params.present?
        return false if matching?(except_params, ref, tag, trigger_request)
      end

      true
    end

    def matching?(patterns, ref, tag, trigger_request)
      patterns.any? do |pattern|
        match_ref?(pattern, ref, tag, trigger_request)
      end
    end

    def match_ref?(pattern, ref, tag, trigger_request)
      pattern, path = pattern.split('@', 2)
      return false if path && path != self.path
      return true if tag && pattern == 'tags'
      return true if !tag && pattern == 'branches'
      return true if trigger_request.present? && pattern == 'triggers'

      if pattern.first == "/" && pattern.last == "/"
        Regexp.new(pattern[1...-1]) =~ ref
      else
        pattern == ref
      end
    end
  end
end
