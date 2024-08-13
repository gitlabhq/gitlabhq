# frozen_string_literal: true

module QA
  module Support
    # Class for storing runtime data for method calls, primarily method calls interacting with the UI
    class CodeRuntimeTracker
      class << self
        # Record data for a method call
        #
        # @param [String] name method name
        # @param [Number] runtime method execution runtime
        # @param [String] call_arg method call argument
        # @return [void]
        def record_method_call(name:, runtime:, filename:, call_arg: nil)
          method_call_data[name] << { runtime: runtime, filename: filename, call_arg: call_arg }
        end

        # Recorded method calls
        #
        # @return [Hash]
        def method_call_data
          @method_calls ||= Hash.new { |hsh, key| hsh[key] = [] }
        end
      end
    end
  end
end
