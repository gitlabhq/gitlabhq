module Gitlab::Ci
  class Config
    module Rule
      ##
      # Job environment rules
      #
      class Environments < Rule::Base
        def initialize(job, config)
          @job, @config = job, config

          @environment = job[:environment]
          @on_stop_name = @environment.try(:on_stop).to_s.to_sym
          @on_stop_job = config[:jobs][@on_stop_name]
          @on_stop_environment = @on_stop_job[:environment]
        end

        def apply!
          return unless has_environment_defined?
          return unless has_on_stop_defined?

          case
          when !stop_job_defined?
            @environment.add_error(:on_stop, 'job not defined')

          when !stop_job_environment_defined?
            @on_stop_job.add_error(:environment, 'not defined')

          when !stop_job_environment_name_valid?
            @on_stop_environment.add_error(
              'name', "does not match environment name defined in `#{@job.name}` job")

          when !stop_job_valid_action_defined?
            @on_stop_environment.add_error(
              'action', 'should be defined as `stop`')
          end
        end

        def has_environment_defined?
          @environment.specified?
        end

        def has_on_stop_defined?
          @environment.has_on_stop?
        end

        def stop_job_defined?
          @on_stop_job.specified?
        end

        def stop_job_environment_defined?
          @on_stop_environment.specified?
        end

        def stop_job_environment_name_valid?
          @environment.name == @on_stop_environment.name
        end

        def stop_job_valid_action_defined?
          @on_stop_environment.action == 'stop'
        end
      end
    end
  end
end
