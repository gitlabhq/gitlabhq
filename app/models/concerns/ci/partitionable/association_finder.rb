# frozen_string_literal: true

module Ci
  module Partitionable
    # Routes the first lazy load of a `belongs_to :pipeline` (or any
    # `belongs_to` to `Ci::Pipeline`) through `Ci::Pipeline.find_by_id`,
    # which `Ci::PartitionableFinder` overrides to prune `ci_pipelines`
    # partitions.
    # Usage:
    #   class MergeTrains::Car < ApplicationRecord
    #     include Ci::Partitionable::AssociationFinder
    #
    #     belongs_to :pipeline, class_name: 'Ci::Pipeline'
    #     partitionable_belongs_to_loader :pipeline
    #   end
    module AssociationFinder
      extend ActiveSupport::Concern

      class_methods do
        def partitionable_belongs_to_loader(name)
          reflection = reflect_on_association(name)

          raise ArgumentError, "No association #{name.inspect} on #{self.name}" unless reflection

          unless reflection.belongs_to? && !reflection.polymorphic?
            raise ArgumentError, "#{name.inspect} must be a non-polymorphic belongs_to"
          end

          foreign_key = reflection.foreign_key

          define_method(name) do
            return super() unless Feature.enabled?(:partitioned_pipeline_association_finder, :current_request)
            return super() if association(name).loaded?

            fk_value = read_attribute(foreign_key)
            return if fk_value.nil?

            # `Ci::PartitionableFinder` overrides `find_by_id` on the target
            # class to prune `ci_pipelines` partitions. Calling `super` would
            # use Rails' default reader, which does not prune.
            association(name).target = reflection.klass.find_by_id(fk_value)
          end
        end
      end
    end
  end
end
