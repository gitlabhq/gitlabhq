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
