module Gitlab
  module Ci
    module Pipeline
      module Chain
        class Sequence
          def initialize(pipeline, command, sequence)
            @pipeline = pipeline
            @completed = []

            @sequence = sequence.map do |chain|
              chain.new(pipeline, command)
            end
          end

          def build!
            @sequence.each do |step|
              step.perform!

              break if step.break?

              @completed << step
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
