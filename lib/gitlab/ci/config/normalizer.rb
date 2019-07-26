# frozen_string_literal: true

module Gitlab
  module Ci
    class Config
      class Normalizer
        def initialize(jobs_config)
          @jobs_config = jobs_config
        end

        def normalize_jobs
          extract_parallelized_jobs!
          return @jobs_config if @parallelized_jobs.empty?

          parallelized_config = parallelize_jobs
          parallelize_dependencies(parallelized_config)
        end

        private

        def extract_parallelized_jobs!
          @parallelized_jobs = {}

          @jobs_config.each do |job_name, config|
            if config[:parallel]
              @parallelized_jobs[job_name] = self.class.parallelize_job_names(job_name, config[:parallel])
            end
          end

          @parallelized_jobs
        end

        def parallelize_jobs
          @jobs_config.each_with_object({}) do |(job_name, config), hash|
            if @parallelized_jobs.key?(job_name)
              @parallelized_jobs[job_name].each { |name, index| hash[name.to_sym] = config.merge(name: name, instance: index) }
            else
              hash[job_name] = config
            end

            hash
          end
        end

        def parallelize_dependencies(parallelized_config)
          parallelized_job_names = @parallelized_jobs.keys.map(&:to_s)
          parallelized_config.each_with_object({}) do |(job_name, config), hash|
            if config[:dependencies] && (intersection = config[:dependencies] & parallelized_job_names).any?
              parallelized_deps = intersection.flat_map { |dep| @parallelized_jobs[dep.to_sym].map(&:first) }
              deps = config[:dependencies] - intersection + parallelized_deps
              hash[job_name] = config.merge(dependencies: deps)
            else
              hash[job_name] = config
            end

            hash
          end
        end

        def self.parallelize_job_names(name, total)
          Array.new(total) { |index| ["#{name} #{index + 1}/#{total}", index + 1] }
        end
      end
    end
  end
end
