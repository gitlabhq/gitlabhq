# frozen_string_literal: true

module ActiveContext
  class Migration
    class V1_0
      class << self
        def milestone(version)
          @milestone = version
        end

        def milestone_version
          @milestone
        end
      end

      def initialize
        @operations = {}
      end

      def migrate!
        raise NotImplementedError, "#{self.class.name} must implement #migrate!"
      end

      def create_collection(name, **options, &block)
        operation = @operations[:"create_#{name}"] ||= OperationResult.new("create_#{name}")

        # Only execute if not already completed
        unless operation.completed?
          ActiveContext.adapter.executor.create_collection(name, **options, &block)
          operation.complete!
        end

        operation.completed?
      end
    end

    def self.[](version)
      version = version.to_s
      name = "V#{version.tr('.', '_')}"

      raise ArgumentError, "Unknown migration version: #{version}" unless const_defined?(name, false)

      const_get(name, false)
    end

    def self.current_version
      1.0
    end
  end
end
