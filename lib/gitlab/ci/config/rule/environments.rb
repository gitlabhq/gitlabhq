module Gitlab
  module Ci
    class Config
      module Rule
        ##
        # Job environment rules
        #
        class Environments < Rule::Base
          def initialize(job, config)
            @job = job
            @job_environment = job[:environment]

            @stop_job_name = @environment.try(:on_stop).to_s
            @stop_job = config[:jobs][@stop_job_name.to_sym]
            @stop_job_environment = @stop_job[:environment]
          end

          def apply!
            return unless @job_environment.specified?
            return unless @job_environment.stoppable?

            if stop_job_undefined?
              @job_environment.error('on_stop', 'job not defined')

            elsif stop_job_environment_undefined?
              @stop_job.error('environment', 'not defined')

            elsif stop_job_environment_name_invalid?
              @stop_job_environment
                .error('name', "does not match environment name " \
                               "defined in `#{@job.name}` job")

            elsif stop_job_action_invalid?
              @stop_job_environment
                .error('action', 'should be defined as `stop`')
            end
          end

          def stop_job_undefined?
            !@stop_job.specified?
          end

          def stop_job_environment_undefined?
            !@stop_job_environment.specified?
          end

          def stop_job_environment_name_invalid?
            @environment.name != @stop_job_environment.name
          end

          def stop_job_action_invalid?
            @stop_job_environment.action != 'stop'
          end
        end
      end
    end
  end
end
