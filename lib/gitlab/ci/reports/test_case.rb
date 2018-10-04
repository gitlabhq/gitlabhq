module Gitlab
  module Ci
    module Reports
      class TestCase
        STATUS_SUCCESS = 'success'.freeze
        STATUS_FAILED = 'failed'.freeze
        STATUS_SKIPPED = 'skipped'.freeze
        STATUS_ERROR = 'error'.freeze
        STATUS_TYPES = [STATUS_SUCCESS, STATUS_FAILED, STATUS_SKIPPED, STATUS_ERROR].freeze

        attr_reader :name, :classname, :execution_time, :status, :file, :system_output, :stack_trace, :key

        def initialize(name:, classname:, execution_time:, status:, file: nil, system_output: nil, stack_trace: nil)
          @name = name
          @classname = classname
          @file = file
          @execution_time = execution_time.to_f
          @status = status
          @system_output = system_output
          @stack_trace = stack_trace
          @key = sanitize_key_name("#{classname}_#{name}")
        end

        private

        def sanitize_key_name(key)
          key.gsub(/[^0-9A-Za-z]/, '-')
        end
      end
    end
  end
end
