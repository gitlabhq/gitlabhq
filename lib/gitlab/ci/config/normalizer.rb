module Gitlab
  module Ci
    class Config
      class Normalizer
        class << self
          def normalize_jobs(jobs_config)
            parallelized_jobs = {}

            parallelized_config = jobs_config.map do |name, config|
              if config&.[](:parallel)
                total = config[:parallel]
                names = parallelize_job_names(name, total)
                parallelized_jobs[name] = names
                Hash[names.collect { |job_name| [job_name.to_sym, config] }]
              else
                { name => config }
              end
            end.reduce(:merge)

            parallelized_config.each do |name, config|
              next unless config[:dependencies]

              deps = config[:dependencies].map do |dep|
                if parallelized_jobs.keys.include?(dep.to_sym)
                  config[:dependencies].delete(dep)
                  parallelized_jobs[dep.to_sym]
                else
                  dep
                end
              end.flatten

              config[:dependencies] = deps
            end
          end

          private

          def parallelize_job_names(name, total)
            jobs = []

            total.times do |idx|
              jobs << "#{name} #{idx + 1}/#{total}"
            end

            jobs
          end
        end
      end
    end
  end
end
