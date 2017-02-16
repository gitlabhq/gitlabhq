module Gitlab
  module Ci
    module Build
      module Response
        class Step
          CONDITION_IF_SUCCEEDED = 'run_if_succeeded'
          CONDITION_ALWAYS = 'run_always'

          RESULT_FAILS_JOB = 'fails_job'
          RESULT_DOESNT_FAIL_JOB = 'doesnt_fail_job'

          attr_reader :name, :script, :condition, :result, :timeout

          class << self
            def from_commands(build)
              self.new(:script,
                       build.commands,
                       build.timeout,
                       CONDITION_IF_SUCCEEDED,
                       RESULT_FAILS_JOB)
            end

            def from_after_script(build)
              after_script = build.options[:after_script]
              return unless after_script

              self.new(:after_script,
                       after_script,
                       build.timeout,
                       CONDITION_ALWAYS,
                       RESULT_DOESNT_FAIL_JOB)
            end
          end

          def initialize(name, script, timeout, condition = CONDITION_IF_SUCCEEDED, result = RESULT_FAILS_JOB)
            @name = name
            @script = script.split("\n")
            @timeout = timeout
            @condition = condition
            @result = result
          end
        end
      end
    end
  end
end
