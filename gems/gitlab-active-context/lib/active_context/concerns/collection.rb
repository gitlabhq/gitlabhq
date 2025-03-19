# frozen_string_literal: true

module ActiveContext
  module Concerns
    module Collection
      extend ActiveSupport::Concern

      class_methods do
        def track!(*objects)
          ActiveContext::Tracker.track!(objects, collection: self)
        end

        def collection_name
          raise NotImplementedError
        end

        def queue
          raise NotImplementedError
        end

        def routing(_)
          raise NotImplementedError
        end

        def reference_klasses
          Array.wrap(reference_klass).tap do |klasses|
            raise NotImplementedError, "#{self} should define reference_klasses or reference_klass" if klasses.empty?
          end
        end

        def reference_klass
          nil
        end

        def collection_record
          ActiveContext::CollectionCache.fetch(collection_name)
        end
      end

      attr_reader :object

      def initialize(object)
        @object = object
      end

      def references
        reference_klasses = Array.wrap(self.class.reference_klasses)
        routing = self.class.routing(object)
        collection_id = self.class.collection_record.id

        reference_klasses.map do |reference_klass|
          reference_klass.serialize(collection_id: collection_id, routing: routing, data: object)
        end
      end
    end
  end
end
