# frozen_string_literal: true

module Gitlab
  module Ci
    module Build
      class Step
        WHEN_ON_FAILURE = 'on_failure'
        WHEN_ON_SUCCESS = 'on_success'
        WHEN_ALWAYS = 'always'

        attr_reader :name
        attr_accessor :script, :timeout, :when, :allow_failure

        class << self
          def from_commands(job)
            self.new(:script).tap do |step|
              step.script = job.options[:before_script].to_a + job.options[:script].to_a
              step.timeout = job.metadata_timeout
              step.when = WHEN_ON_SUCCESS
            end
          end

          def from_release(job)
            return unless job.options[:release]

            self.new(:release).tap do |step|
              step.script = Gitlab::Ci::Build::Releaser.new(job: job).script
              step.timeout = job.metadata_timeout
              step.when = WHEN_ON_SUCCESS
            end
          end

          def from_after_script(job)
            after_script = job.options[:after_script]
            return unless after_script

            self.new(:after_script).tap do |step|
              step.script = after_script
              step.timeout = job.metadata_timeout
              step.when = WHEN_ALWAYS
              step.allow_failure = true
            end
          end
        end

        def initialize(name)
          @name = name
          @allow_failure = false
        end
      end
    end
  end
end
