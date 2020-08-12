# frozen_string_literal: true

module Gitlab
  module Ci
    module Pipeline
      module Chain
        class Sequence
          def initialize(pipeline, command, sequence)
            @pipeline = pipeline
            @command = command
            @sequence = sequence
            @start = Time.now
          end

          def build!
            @sequence.each do |step_class|
              step = step_class.new(@pipeline, @command)

              step.perform!
              break if step.break?
            end

            @command.observe_creation_duration(Time.now - @start)
            @command.observe_pipeline_size(@pipeline)

            @pipeline
          end
        end
      end
    end
  end
end
