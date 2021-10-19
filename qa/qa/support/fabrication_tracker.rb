# frozen_string_literal: true

module QA
  module Support
    # Threadsafe fabrication time tracker
    #
    # Ongoing fabrication is added to callstack by start_fabrication and taken out by finish_fabrication
    #
    # Fabrication runtime is saved only for the first fabrication in the stack to properly represent the real time
    # fabrications might take as top level fabrication runtime will always include nested fabrications runtime
    #
    class FabricationTracker
      class << self
        # Start fabrication and increment ongoing fabrication count
        #
        # @return [void]
        def start_fabrication
          Thread.current[:fabrications_ongoing] = 0 unless Thread.current.key?(:fabrications_ongoing)

          Thread.current[:fabrications_ongoing] += 1
        end

        # Finish fabrication and decrement ongoing fabrication count
        #
        # @return [void]
        def finish_fabrication
          Thread.current[:fabrications_ongoing] -= 1
        end

        # Save fabrication time if it's first in fabrication stack
        #
        # @param [Symbol] type
        # @param [Symbol] time
        # @return [void]
        def save_fabrication(type, time)
          return unless Thread.current.key?(type)
          return unless top_level_fabrication?

          Thread.current[type] += time
        end

        private

        # Check if current fabrication is the only one in the stack
        #
        # @return [Boolean]
        def top_level_fabrication?
          Thread.current[:fabrications_ongoing] == 1
        end
      end
    end
  end
end
