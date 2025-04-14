# frozen_string_literal: true

module ActiveContext
  module Concerns
    module Collection
      extend ActiveSupport::Concern

      class_methods do
        def track!(*objects)
          ActiveContext::Tracker.track!(objects, collection: self)
        end

        def search(user:, query:)
          ActiveContext.adapter.search(query: query, user: user, collection: self)
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

        def ids_to_objects(_)
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

        def redact_unauthorized_results!(result)
          objects = ids_to_objects(result.ids)
          id_to_object_map = objects.index_by { |object| object.id.to_s }

          authorized_ids = Set.new(objects.select do |object|
            authorized_to_see_object?(result.user, object)
          end.map(&:id).map(&:to_s))

          result.ids
            .select { |id| authorized_ids.include?(id.to_s) }
            .map { |id| id_to_object_map[id.to_s] }
        end

        def authorized_to_see_object?(user, object)
          return true unless object.respond_to?(:to_ability_name) && DeclarativePolicy.has_policy?(object)

          Ability.allowed?(user, :"read_#{object.to_ability_name}", object)
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
