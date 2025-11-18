# frozen_string_literal: true

module ActiveContext
  class Migration
    class V1_0
      MigrationError = Class.new(StandardError)

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
        operation = initialize_operation("create_#{name}")

        unless operation.completed?
          ActiveContext.adapter.executor.create_collection(name, **options, &block)
          operation.complete!
        end

        operation.completed?
      end

      def update_collection_metadata(collection:, metadata:)
        raise MigrationError, 'Metadata should be a hash' unless metadata.is_a?(::Hash)

        operation = initialize_operation("update_collection_metadata_#{metadata.to_json}")

        unless operation.completed?
          collection.collection_record.update_metadata!(metadata.merge(collection_class: collection.name))
          operation.complete!
        end

        operation.completed?
      end

      def drop_collection(name)
        operation = initialize_operation("drop_#{name}")

        unless operation.completed?
          ActiveContext.adapter.executor.drop_collection(name)
          operation.complete!
        end

        operation.completed?
      end

      def all_operations_completed?
        @operations.values.all?(&:completed?)
      end

      private

      def initialize_operation(key)
        @operations[key] ||= OperationResult.new(key)
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
