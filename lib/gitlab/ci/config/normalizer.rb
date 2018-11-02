# frozen_string_literal: true

module Gitlab
  module Ci
    class Config
      class Normalizer
        class << self
          def normalize_jobs(jobs_config)
            parallelized_config, parallelized_jobs = parallelize_jobs(jobs_config)
            parallelize_dependencies(parallelized_config, parallelized_jobs)
          end

          private

          def parallelize_jobs(jobs_config)
            parallelized_jobs = {}

            parallelized_config = jobs_config.map do |name, config|
              if config[:parallel]
                total = config[:parallel]
                names = parallelize_job_names(name, total)
                parallelized_jobs[name] = names.map(&:first)
                Hash[names.collect { |job_name, index| [job_name.to_sym, config.merge(name: job_name, instance: index)] }]
              else
                { name => config }
              end
            end.reduce(:merge)

            [parallelized_config, parallelized_jobs]
          end

          def parallelize_dependencies(jobs_config, parallelized_jobs)
            jobs_config.map do |name, config|
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

          def parallelize_job_names(name, total)
            jobs = []

            1.upto(total) do |idx|
              jobs << ["#{name} #{idx}/#{total}", idx]
            end

            jobs
          end
        end
      end
    end
  end
end
