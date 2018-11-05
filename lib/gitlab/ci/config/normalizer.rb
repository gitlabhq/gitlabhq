# frozen_string_literal: true

module Gitlab
  module Ci
    class Config
      class Normalizer
        class << self
          def normalize_jobs(jobs_config)
            parallelized_jobs = extract_parallelized_jobs(jobs_config)
            parallelized_config = parallelize_jobs(jobs_config, parallelized_jobs)
            parallelize_dependencies(parallelized_config, parallelized_jobs)
          end

          private

          def extract_parallelized_jobs(jobs_config)
            parallelized_jobs = {}

            jobs_config.each do |job_name, config|
              if config[:parallel]
                parallelized_jobs[job_name] = parallelize_job_names(job_name, config[:parallel])
              end
            end

            parallelized_jobs
          end

          def parallelize_jobs(jobs_config, parallelized_jobs)
            jobs_config.each_with_object({}) do |(job_name, config), hash|
              if parallelized_jobs.keys.include?(job_name)
                parallelized_jobs[job_name].each { |name, index| hash[name.to_sym] = config.merge(name: name, instance: index) }
              else
                hash[job_name] = config
              end

              hash
            end
          end

          def parallelize_dependencies(parallelized_config, parallelized_jobs)
            parallelized_config.each_with_object({}) do |(job_name, config), hash|
              intersection = config[:dependencies] & parallelized_jobs.keys.map(&:to_s)
              if intersection && intersection.any?
                deps = intersection.map { |dep| parallelized_jobs[dep.to_sym].map(&:first) }.flatten
                hash[job_name] = config.merge(dependencies: deps)
              else
                hash[job_name] = config
              end

              hash
            end
          end

          def parallelize_job_names(name, total)
            Array.new(total) { |index| ["#{name} #{index + 1}/#{total}", index + 1] }
          end
        end
      end
    end
  end
end
