# frozen_string_literal: true

module Gitlab
  module Ci
    class Config
      class Normalizer
        include Gitlab::Utils::StrongMemoize

        def initialize(jobs_config)
          @jobs_config = jobs_config
        end

        def normalize_jobs
          return {} unless @jobs_config
          return @jobs_config if parallelized_jobs.empty?

          expand_parallelize_jobs do |job_name, config|
            if config[:dependencies]
              config[:dependencies] = expand_names(config[:dependencies])
            end

            if job_needs = config.dig(:needs, :job)
              config[:needs][:job] = expand_needs(job_needs)
            end

            config
          end
        end

        private

        def expand_names(job_names)
          return unless job_names

          job_names.flat_map do |job_name|
            parallelized_jobs[job_name.to_sym]&.map(&:name) || job_name
          end
        end

        def expand_needs(job_needs)
          return unless job_needs

          job_needs.flat_map do |job_need|
            job_need_name = job_need[:name].to_sym

            if all_jobs = parallelized_jobs[job_need_name]
              if job_need.key?(:parallel)
                all_jobs = parallelize_job_config(job_need_name, job_need.delete(:parallel))
              end

              all_jobs.map { |job| job_need.merge(name: job.name) }
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

        def expand_parallelize_jobs
          @jobs_config.each_with_object({}) do |(job_name, config), hash|
            if parallelized_jobs.key?(job_name)
              parallelized_jobs[job_name].each do |job|
                hash[job.name.to_sym] =
                  yield(job.name, config.deep_merge(job.attributes))
              end
            else
              hash[job_name] = yield(job_name, config)
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
