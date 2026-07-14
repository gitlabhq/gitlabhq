# frozen_string_literal: true

module Ci
  module Partitionable
    # Partition-aware loading for `belongs_to :pipeline` associations, so they
    # resolve through a partition-scoped lookup instead of a full table scan.
    module AssociationFinder
      extend ActiveSupport::Concern

      included do
        class_attribute :partitioned_pipeline_loaders, default: {}
      end

      module PipelineRelationPreload
        def preload_associations(records)
          return super unless Feature.enabled?(:partition_aware_pipeline_preload, :current_request)

          loaders = klass.partitioned_pipeline_loaders
          requested = loaders.keys & preload_keys

          requested.each do |name|
            foreign_key = loaders[name]
            ids = records.filter_map { |record| record.read_attribute(foreign_key) }.uniq
            next if ids.empty?

            pipelines = ::Gitlab::Ci::Pipeline::BulkByIdLookup.new(ids, fallback: false).execute

            ::ActiveRecord::Associations::Preloader.new(
              records: records,
              associations: name,
              available_records: pipelines
            ).call
          end

          super
        end

        private

        def preload_keys
          (preload_values + includes_values).flat_map do |value|
            value.is_a?(Hash) ? value.keys : value
          end
        end
      end

      class_methods do
        def with_partition_aware_preload
          extending(PipelineRelationPreload)
        end

        # Resolves an unloaded association through the target's partition-aware
        # `find_by_id`, deferring to the default reader if it's already loaded.
        # Usage:
        #   class MergeTrains::Car < ApplicationRecord
        #     include Ci::Partitionable::AssociationFinder
        #
        #     belongs_to :pipeline, class_name: 'Ci::Pipeline'
        #     partitionable_belongs_to_loader :pipeline
        #   end
        #
        def partitionable_belongs_to_loader(name)
          reflection = reflect_on_association(name)

          raise ArgumentError, "No association #{name.inspect} on #{self.name}" unless reflection

          unless reflection.belongs_to? && !reflection.polymorphic?
            raise ArgumentError, "#{name.inspect} must be a non-polymorphic belongs_to"
          end

          foreign_key = reflection.foreign_key

          self.partitioned_pipeline_loaders = partitioned_pipeline_loaders.merge(name => foreign_key)

          define_method(name) do
            return super() if association(name).loaded?

            fk_value = read_attribute(foreign_key)
            return if fk_value.nil?

            # Calling `super` would use Rails' default reader, which does not prune
            association(name).target = reflection.klass.find_by_id(fk_value)
          end
        end
      end
    end
  end
end
