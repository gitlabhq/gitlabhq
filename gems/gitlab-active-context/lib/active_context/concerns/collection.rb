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
      end

      attr_reader :object

      def initialize(object)
        @object = object
      end

      def references
        raise NotImplementedError
      end
    end
  end
end
