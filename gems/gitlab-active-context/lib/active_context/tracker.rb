# frozen_string_literal: true

module ActiveContext
  class Tracker
    class << self
      def track!(*objects, collection:, queue: nil)
        references = collect_references(objects.flatten, collection)

        return 0 if references.empty?

        queue_to_use = queue || collection.queue

        queue_to_use.push(references)

        references.count
      end

      private

      def collect_references(objects, collection)
        objects.flat_map do |obj|
          collection.new(obj).references
        end
      end
    end
  end
end
