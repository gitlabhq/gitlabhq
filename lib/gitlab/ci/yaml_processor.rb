# frozen_string_literal: true

# This is the CI Linter component that runs the syntax validations
# while parsing the YAML config into a data structure that is
# then presented to the caller as result object.
# After syntax validations (done by Ci::Config), this component also
# runs logical validation on the built data structure.
module Gitlab
  module Ci
    class YamlProcessor
      include Gitlab::Utils::StrongMemoize

      ValidationError = Class.new(StandardError)

      def initialize(config_content, opts = {})
        @config_content = config_content
        @opts = opts
      end

      def execute
        if @config_content.blank?
          return Result.new(errors: ['Please provide content of .gitlab-ci.yml'])
        end

        verify_project_sha! if verify_project_sha?

        @ci_config = Gitlab::Ci::Config.new(@config_content, **ci_config_opts)

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

      attr_reader :opts

      def ci_config_opts
        @opts
      end

      def project
        @opts[:project]
      end

      def sha
        @opts[:sha]
      end

      def verify_project_sha?
        @opts.delete(:verify_project_sha) || false
      end
      strong_memoize_attr :verify_project_sha?

      def run_logical_validations!
        @stages = @ci_config.stages
        @jobs = @ci_config.normalized_jobs

        @jobs.each do |name, job|
          validate_job!(name, job)
        end

        check_circular_dependencies
      end

      # Overridden in EE
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
          error!("#{name} job: chosen stage #{job[:stage]} does not exist; available stages are #{@stages.join(', ')}")
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
        validate_needs_specification!(name, job.dig(:needs, :job))

        job[:rules]&.each do |rule|
          validate_needs_specification!(name, rule.dig(:needs, :job))
        end
      end

      def validate_needs_specification!(name, needs)
        return unless needs

        needs.each do |need|
          validate_job_dependency!(name, need[:name], 'need', optional: need[:optional])
        end

        duplicated_needs =
          needs
          .group_by { |need| need[:name] }
          .select { |_, items| items.count > 1 }
          .keys

        unless duplicated_needs.empty?
          error!("#{name} has the following needs duplicated: #{duplicated_needs.join(', ')}.")
        end
      end

      def validate_job_dependency!(name, dependency, dependency_type = 'dependency', optional: false)
        unless @jobs[dependency.to_sym]
          # Here, we ignore the optional needed job if it is not in the result YAML due to the `include`
          # rules. In `lib/gitlab/ci/pipeline/seed/build.rb`, we use `optional` again to ignore the
          # optional needed job in case it is excluded from the pipeline due to the job's rules.
          return if optional

          error!("#{name} job: undefined #{dependency_type}: #{dependency}")
        end

        # A parallel job's name is expanded in Config::Normalizer so we must revalidate the name length here
        if dependency_type == 'need' && dependency.length > ::Ci::BuildNeed::MAX_JOB_NAME_LENGTH
          error!("#{name} job: need `#{dependency}` name is too long " \
                 "(maximum is #{::Ci::BuildNeed::MAX_JOB_NAME_LENGTH} characters)")
        end

        job_stage_index = stage_index(name)
        dependency_stage_index = stage_index(dependency)

        unless dependency_stage_index.present? && dependency_stage_index <= job_stage_index
          error!("#{name} job: #{dependency_type} #{dependency} is not defined in current or prior stages")
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

      def check_circular_dependencies
        jobs = @jobs.values.to_h do |job|
          name = job[:name].to_s
          needs = job.dig(:needs, :job).to_a

          [name, needs.map { |need| need[:name].to_s }]
        end

        Dag.check_circular_dependencies!(jobs)
      end

      def error!(message)
        raise ValidationError, message
      end

      def verify_project_sha!
        return unless project && sha && project.repository_exists? && project.commit(sha)

        unless project_ref_contains_sha?
          error!('Could not validate configuration. The configuration originates from an external ' \
                 'project or a commit not associated with a Git reference (a detached commit)')
        end
      end

      def project_ref_contains_sha?
        # A 5-minute cache TTL is sufficient to prevent Gitaly load issues while also mitigating rare
        # use cases concerning stale data. For example, when an external commit gets merged into the
        # project, there may be at most a 5-minute window where the `sha` is still considered external.
        Rails.cache.fetch(['project', project.id, 'ref/contains/sha', sha], expires_in: 5.minutes) do
          repo = project.repository
          repo.branch_names_contains(sha, limit: 1).any? || repo.tag_names_contains(sha, limit: 1).any?
        end
      end
    end
  end
end

Gitlab::Ci::YamlProcessor.prepend_mod
