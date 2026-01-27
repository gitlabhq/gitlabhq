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

      def migrate!
        raise NotImplementedError, "#{self.class.name} must implement #migrate!"
      end

      def skip?
        false
      end

      def completed?
        raise NotImplementedError, "#{self.class.name} must implement #completed?"
      end

      def create_collection(name, **options, &block)
        ActiveContext.adapter.executor.create_collection(name, **options, &block)
      end

      def update_collection_metadata(collection:, metadata:)
        raise MigrationError, 'Metadata should be a hash' unless metadata.is_a?(::Hash)

        collection.collection_record.update_metadata!(metadata.merge(collection_class: collection.name))
      end

      def drop_collection(name)
        ActiveContext.adapter.executor.drop_collection(name)
      end

      def add_field(name, &block)
        ActiveContext.adapter.executor.add_field(name, &block)
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
