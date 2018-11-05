# frozen_string_literal: true

module Gitlab
  module Ci
    class Config
      class Normalizer
        def initialize(jobs_config)
          @jobs_config = jobs_config
        end

        def normalize_jobs
          parallelized_jobs = parallelize_jobs
          parallelize_dependencies(parallelized_jobs)
        end

        private

        def parallelize_jobs
          parallelized_jobs = {}

          @jobs_config = @jobs_config.map do |name, config|
            if config[:parallel]
              total = config[:parallel]
              names = self.class.parallelize_job_names(name, total)
              parallelized_jobs[name] = names.map(&:first)
              Hash[names.collect { |job_name, index| [job_name.to_sym, config.merge(name: job_name, instance: index)] }]
            else
              { name => config }
            end
          end.reduce(:merge)

          parallelized_jobs
        end

        def parallelize_dependencies(parallelized_jobs)
          @jobs_config.map do |name, config|
            if config[:dependencies]
              deps = config[:dependencies].map do |dep|
                if parallelized_jobs.keys.include?(dep.to_sym)
                  parallelized_jobs[dep.to_sym]
                else
                  dep
                end
              end.flatten

              { name => config.merge(dependencies: deps) }
            else
              { name => config }
            end
          end.reduce(:merge)
        end

        def self.parallelize_job_names(name, total)
          Array.new(total) { |index| ["#{name} #{index + 1}/#{total}", index + 1] }
        end
      end
    end
  end
end
