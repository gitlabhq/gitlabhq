module Ci
  class GitlabCiYamlProcessor
    class ValidationError < StandardError; end

    include Gitlab::Ci::Config::Node::LegacyValidationHelpers

    DEFAULT_STAGE = 'test'
    ALLOWED_YAML_KEYS = [:before_script, :after_script, :image, :services, :types, :stages, :variables, :cache]
    ALLOWED_JOB_KEYS = [:tags, :script, :only, :except, :type, :image, :services,
                        :allow_failure, :type, :stage, :when, :artifacts, :cache,
                        :dependencies, :before_script, :after_script, :variables,
                        :environment]
    ALLOWED_CACHE_KEYS = [:key, :untracked, :paths]
    ALLOWED_ARTIFACTS_KEYS = [:name, :untracked, :paths, :when, :expire_in]

    attr_reader :path, :cache, :stages

    def initialize(config, path = nil)
      @ci_config = Gitlab::Ci::Config.new(config)
      @config, @path = @ci_config.to_hash, path

      unless @ci_config.valid?
        raise ValidationError, @ci_config.errors.first
      end

      initial_parsing
    rescue Gitlab::Ci::Config::Loader::FormatError => e
      raise ValidationError, e.message
    end

    def builds_for_stage_and_ref(stage, ref, tag = false, trigger_request = nil)
      builds.select do |build|
        build[:stage] == stage &&
          process?(build[:only], build[:except], ref, tag, trigger_request)
      end
    end

    def builds
      @jobs.map do |name, job|
        build_job(name, job)
      end
    end

    def global_variables
      @variables
    end

    def job_variables(name)
      job = @jobs[name.to_sym]
      return [] unless job

      job[:variables] || []
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
        validate_job!(name, job)
      end
    end

    def build_job(name, job)
      {
        stage_idx: @stages.index(job[:stage]),
        stage: job[:stage],
        commands: job[:commands],
        tag_list: job[:tags] || [],
        name: name,
        only: job[:only],
        except: job[:except],
        allow_failure: job[:allow_failure] || false,
        when: job[:when] || 'on_success',
        environment: job[:environment],
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

    def validate_job!(name, job)
      raise ValidationError, "Unknown parameter: #{name}" unless job.is_a?(Hash) && job.has_key?(:script)

      validate_job_keys!(name, job)
      validate_job_types!(name, job)

      validate_job_variables!(name, job) if job[:variables]
      validate_job_cache!(name, job) if job[:cache]
      validate_job_artifacts!(name, job) if job[:artifacts]
      validate_job_dependencies!(name, job) if job[:dependencies]
    end

    def validate_job_keys!(name, job)
      ##
      # TODO, remove refactoring keys
      #
      refactoring_keys = [:commands]
      job.keys.each do |key|
        unless (ALLOWED_JOB_KEYS + refactoring_keys).include? key
          raise ValidationError, "#{name} job: unknown parameter #{key}"
        end
      end
    end

    def validate_job_types!(name, job)
      if job[:image] && !validate_string(job[:image])
        raise ValidationError, "#{name} job: image should be a string"
      end

      if job[:services] && !validate_array_of_strings(job[:services])
        raise ValidationError, "#{name} job: services should be an array of strings"
      end

      if job[:tags] && !validate_array_of_strings(job[:tags])
        raise ValidationError, "#{name} job: tags parameter should be an array of strings"
      end

      if job[:only] && !validate_array_of_strings_or_regexps(job[:only])
        raise ValidationError, "#{name} job: only parameter should be an array of strings or regexps"
      end

      if job[:except] && !validate_array_of_strings_or_regexps(job[:except])
        raise ValidationError, "#{name} job: except parameter should be an array of strings or regexps"
      end

      if job[:allow_failure] && !validate_boolean(job[:allow_failure])
        raise ValidationError, "#{name} job: allow_failure parameter should be an boolean"
      end

      if job[:when] && !job[:when].in?(%w[on_success on_failure always])
        raise ValidationError, "#{name} job: when parameter should be on_success, on_failure or always"
      end

      if job[:environment] && !validate_environment(job[:environment])
        raise ValidationError, "#{name} job: environment parameter #{Gitlab::Regex.environment_name_regex_message}"
      end
    end

    def validate_job_variables!(name, job)
      unless validate_variables(job[:variables])
        raise ValidationError,
          "#{name} job: variables should be a map of key-value strings"
      end
    end

    def validate_job_cache!(name, job)
      job[:cache].keys.each do |key|
        unless ALLOWED_CACHE_KEYS.include? key
          raise ValidationError, "#{name} job: cache unknown parameter #{key}"
        end
      end

      if job[:cache][:key] && !validate_string(job[:cache][:key])
        raise ValidationError, "#{name} job: cache:key parameter should be a string"
      end

      if job[:cache][:untracked] && !validate_boolean(job[:cache][:untracked])
        raise ValidationError, "#{name} job: cache:untracked parameter should be an boolean"
      end

      if job[:cache][:paths] && !validate_array_of_strings(job[:cache][:paths])
        raise ValidationError, "#{name} job: cache:paths parameter should be an array of strings"
      end
    end

    def validate_job_artifacts!(name, job)
      job[:artifacts].keys.each do |key|
        unless ALLOWED_ARTIFACTS_KEYS.include? key
          raise ValidationError, "#{name} job: artifacts unknown parameter #{key}"
        end
      end

      if job[:artifacts][:name] && !validate_string(job[:artifacts][:name])
        raise ValidationError, "#{name} job: artifacts:name parameter should be a string"
      end

      if job[:artifacts][:untracked] && !validate_boolean(job[:artifacts][:untracked])
        raise ValidationError, "#{name} job: artifacts:untracked parameter should be an boolean"
      end

      if job[:artifacts][:paths] && !validate_array_of_strings(job[:artifacts][:paths])
        raise ValidationError, "#{name} job: artifacts:paths parameter should be an array of strings"
      end

      if job[:artifacts][:when] && !job[:artifacts][:when].in?(%w[on_success on_failure always])
        raise ValidationError, "#{name} job: artifacts:when parameter should be on_success, on_failure or always"
      end

      if job[:artifacts][:expire_in] && !validate_duration(job[:artifacts][:expire_in])
        raise ValidationError, "#{name} job: artifacts:expire_in parameter should be a duration"
      end
    end

    def validate_job_dependencies!(name, job)
      unless validate_array_of_strings(job[:dependencies])
        raise ValidationError, "#{name} job: dependencies parameter should be an array of strings"
      end

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
