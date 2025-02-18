# frozen_string_literal: true

module ActiveContext
  module Concerns
    module Collection
      extend ActiveSupport::Concern

      class_methods do
        def track!(*objects)
          ActiveContext::Tracker.track!(objects, collection: self)
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
      end

      attr_reader :object

      def initialize(object)
        @object = object
      end

      def references
        reference_klasses = Array.wrap(self.class.reference_klasses)
        routing = self.class.routing(object)

        reference_klasses.map do |reference_klass|
          reference_klass.serialize(object, routing)
        end
      end
    end
  end
end
