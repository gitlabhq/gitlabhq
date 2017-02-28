module Gitlab
  module Ci
    module Build
      module Response
        class Step
          CONDITION_ON_FAILURE = 'on_failure'.freeze
          CONDITION_ON_SUCCESS = 'on_success'.freeze
          CONDITION_ALWAYS = 'always'.freeze

          attr_reader :name, :script, :when, :allow_failure, :timeout

          class << self
            def from_commands(build)
              self.new(:script,
                       build.commands,
                       build.timeout,
                       CONDITION_ON_SUCCESS,
                       false)
            end

            def from_after_script(build)
              after_script = build.options[:after_script]
              return unless after_script

              self.new(:after_script,
                       after_script,
                       build.timeout,
                       CONDITION_ALWAYS,
                       true)
            end
          end

          def initialize(name, script, timeout, when_condition = CONDITION_ON_SUCCESS, allow_failure = true)
            @name = name
            @script = script.split("\n")
            @timeout = timeout
            @when = when_condition
            @allow_failure = allow_failure
          end
        end
      end
    end
  end
end
