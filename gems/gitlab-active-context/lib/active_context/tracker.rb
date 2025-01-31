# frozen_string_literal: true

module ActiveContext
  class Tracker
    class << self
      def track!(*objects, collection: nil, queue: nil)
        references = collect_references(objects.flatten, collection)

        return 0 if references.empty?

        queue_to_use = queue || collection.queue

        queue_to_use.push(references)

        references.count
      end

      private

      def collect_references(objects, collection)
        objects.flat_map do |obj|
          if obj.is_a?(ActiveContext::Reference)
            obj.serialize
          elsif obj.is_a?(String)
            obj
          else
            next collection.new(obj).references if collection

            logger.warn("ActiveContext unable to track `#{obj}`: Collection must be specified")
            []
          end
        end
      end

      def logger
        ActiveContext::Config.logger
      end
    end
  end
end
