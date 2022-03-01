# frozen_string_literal: true

require 'singleton'

module QA
  module Resource
    #
    # This singleton class collects all reusable resources used by tests and allows operations to be performed on them
    # all. For example, verifying their state after tests have run and might have changed them.
    #
    class ReusableCollection
      include Singleton

      attr_accessor :resource_classes

      def initialize
        @resource_classes = {}
      end

      # Yields each resource in the collection.
      #
      # @yieldparam [Symbol] reuse_as the name that identifies the resource instance.
      # @yieldparam [QA::Resource] reuse_instance the resource.
      def each_resource
        resource_classes.each_value do |reuse_instances|
          reuse_instances.each do |reuse_as, reuse_instance|
            yield reuse_as, reuse_instance[:resource]
          end
        end
      end

      class << self
        # Removes all created resources that are included in the collection.
        def remove_all_via_api!
          instance.each_resource do |reuse_as, resource|
            next QA::Runtime::Logger.debug("#{resource.class.name} reused as :#{reuse_as} has already been removed.") unless resource.exists?
            next if resource.respond_to?(:marked_for_deletion?) && resource.marked_for_deletion?

            resource.method(:remove_via_api!).super_method.call
          end
        end

        # Validates the reuse of each resource as defined by the resource class of each resource in the collection.
        def validate_resource_reuse
          instance.each_resource { |_, resource| resource.validate_reuse }
        end

        # Yields the collection of resources to allow resource classes to register themselves with the collection.
        #
        # @yieldparam [Hash] resource_classes the resource classes in the collection.
        def register_resource_classes
          yield instance.resource_classes
        end
      end
    end
  end
end
