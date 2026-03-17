# frozen_string_literal: true

module ActiveContext
  module Task
    class V1_0
      TaskError = Class.new(StandardError)
      MissingParamError = Class.new(TaskError)

      delegate :executor, :full_collection_name, to: :adapter
      delegate :add_field, :nullify_field, to: :executor

      class << self
        def batched!
          @batched = true
        end

        def batched?
          @batched == true
        end
      end

      attr_reader :task_record

      def initialize(task_record = nil)
        @task_record = task_record
        validate_params!
      end

      def execute!
        raise NotImplementedError, "#{self.class.name} must implement #execute!"
      end

      def completed?
        raise NotImplementedError, "#{self.class.name} must implement #completed?" if self.class.batched?

        true
      end

      def params
        task_record&.params || {}
      end

      def required_params
        []
      end

      def connection
        task_record&.connection
      end

      private

      def adapter
        ActiveContext.adapter
      end

      def validate_params!
        missing = required_params.select { |key| params[key].nil? }
        return if missing.empty?

        raise MissingParamError, "Missing required params: #{missing.join(', ')}"
      end
    end

    def self.[](version)
      version = version.to_s
      name = "V#{version.tr('.', '_')}"

      raise ArgumentError, "Unknown task version: #{version}" unless const_defined?(name, false)

      const_get(name, false)
    end
  end
end
