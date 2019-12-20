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
            parallelized_jobs[job_name.to_sym] || job_name
          end
        end

        def expand_needs(job_needs)
          return unless job_needs

          job_needs.flat_map do |job_need|
            job_need_name = job_need[:name].to_sym

            if all_job_names = parallelized_jobs[job_need_name]
              all_job_names.map do |job_name|
                job_need.merge(name: job_name)
              end
            else
              job_need
            end
          end
        end

        def parallelized_jobs
          strong_memoize(:parallelized_jobs) do
            @jobs_config.each_with_object({}) do |(job_name, config), hash|
              next unless config[:parallel]

              hash[job_name] = self.class.parallelize_job_names(job_name, config[:parallel])
            end
          end
        end

        def expand_parallelize_jobs
          @jobs_config.each_with_object({}) do |(job_name, config), hash|
            if parallelized_jobs.key?(job_name)
              parallelized_jobs[job_name].each_with_index do |name, index|
                hash[name.to_sym] =
                  yield(name, config.merge(name: name, instance: index + 1))
              end
            else
              hash[job_name] = yield(job_name, config)
            end
          end
        end

        def self.parallelize_job_names(name, total)
          Array.new(total) { |index| "#{name} #{index + 1}/#{total}" }
        end
      end
    end
  end
end
