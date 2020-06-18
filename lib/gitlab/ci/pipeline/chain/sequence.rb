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
            @completed = []
            @start = Time.now
          end

          def build!
            @sequence.each do |chain|
              step = chain.new(@pipeline, @command)

              step.perform!
              break if step.break?

              @completed.push(step)
            end

            @pipeline.tap do
              yield @pipeline, self if block_given?

              @command.observe_creation_duration(Time.now - @start)
              @command.observe_pipeline_size(@pipeline)
            end
          end

          def complete?
            @completed.size == @sequence.size
          end
        end
      end
    end
  end
end
