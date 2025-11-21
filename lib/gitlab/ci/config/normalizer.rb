# frozen_string_literal: true

module Gitlab
  module Ci
    class Config
      class Normalizer
        include Gitlab::Utils::StrongMemoize

        def initialize(jobs_config)
          @jobs_config = jobs_config
          @errors = []
        end

        def normalize_jobs
          return {} unless @jobs_config
          return @jobs_config if parallelized_jobs.empty?

          @jobs_config.each_with_object({}) do |(job_name, config), normalized_jobs|
            if parallelized_jobs.key?(job_name)
              parallelized_jobs[job_name].each do |job|
                expanded_config = config.deep_merge(job.attributes)
                normalized_jobs[job.name.to_sym] = normalize_job(job_name, expanded_config)
              end
            else
              normalized_jobs[job_name] = normalize_job(job_name, config)
            end
          end
        end

        # Deduplicate errors since multiple matrix jobs may generate identical errors
        # for the same missing matrix variable
        def errors
          @errors.uniq
        end

        private

        attr_reader :project

        def normalize_job(job_name, config)
          if interpolated_needs = apply_matrix_interpolation(job_name, config)
            config[:needs] = interpolated_needs
          end

          config[:dependencies] = expand_parallelized_job_names(config[:dependencies]) if config[:dependencies]

          if job_needs = config.dig(:needs, :job)
            config[:needs][:job] = expand_parallelized_needs(job_needs)
          end

          config
        end

        def apply_matrix_interpolation(job_name, config)
          return unless config[:job_variables] && config[:needs]

          interpolator = Interpolation::MatrixInterpolator.new(config[:job_variables])
          interpolated_needs = interpolator.interpolate(config[:needs])

          if interpolator.errors.empty?
            interpolated_needs
          else
            job_errors = interpolator.errors.map { |error| "#{job_name} job: #{error}" }

            @errors.concat(job_errors)

            nil
          end
        end

        def expand_parallelized_job_names(job_names)
          job_names.flat_map do |job_name|
            parallelized_jobs[job_name.to_sym]&.map(&:name) || job_name
          end
        end

        def expand_parallelized_needs(job_needs)
          job_needs.flat_map do |job_need|
            job_need_name = job_need[:name].to_sym

            if all_jobs = parallelized_jobs[job_need_name]
              if job_need.key?(:parallel)
                all_jobs = parallelize_job_config(job_need_name, job_need[:parallel])
              end

              all_jobs.map { |job| job_need.except(:parallel).merge(name: job.name) }
            else
              job_need
            end
          end
        end

        def parallelized_jobs
          strong_memoize(:parallelized_jobs) do
            @jobs_config.each_with_object({}) do |(job_name, config), hash|
              next unless config[:parallel]

              hash[job_name] = parallelize_job_config(job_name, config[:parallel])
            end
          end
        end

        def parallelize_job_config(name, config)
          Normalizer::Factory.new(name, config).create
        end
      end
    end
  end
end
