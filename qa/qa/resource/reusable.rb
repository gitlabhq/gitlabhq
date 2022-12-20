# frozen_string_literal: true

module QA
  module Resource
    #
    # This module includes methods that allow resource classes to be reused safely. It should be prepended to a new
    # reusable version of an existing resource class. See Resource::Project and ReusableResource::Project for an example.
    # Reusable resource classes must also be registered with a resource collection that will manage cleanup.
    #
    # @example Register a resource class with a collection
    #   QA::Resource::ReusableCollection.register_resource_classes do |collection|
    #     QA::Resource::ReusableProject.register(collection)
    #   end
    module Reusable
      attr_accessor :reuse,
                    :reuse_as

      ResourceReuseError = Class.new(RuntimeError)

      def self.prepended(base)
        base.extend(ClassMethods)
      end

      # Gets an existing resource if it exists and the specified attributes of the resource are valid.
      # Creates a new instance of the resource if it does not exist.
      #
      # @return [String] The URL of the resource.
      def fabricate_via_api!
        validate_reuse_preconditions

        resource_web_url(api_get)
      rescue Errors::ResourceNotFoundError
        super
      ensure
        self.class.resources[reuse_as] ||= {
          tests: Set.new,
          resource: self
        }

        self.class.resources[reuse_as][:attributes] ||= all_attributes.index_with do |attribute_name|
          instance_variable_get("@#{attribute_name}")
        end
        self.class.resources[reuse_as][:tests] << Runtime::Example.location
      end

      # Overrides remove_via_api! to log a debug message stating that removal will happen after the suite completes.
      #
      # @return [nil]
      def remove_via_api!
        QA::Runtime::Logger.debug("#{self.class.name} - deferring removal until after suite")
      end

      # Object comparison
      #
      # @param [QA::Resource::Base] other
      # @return [Boolean]
      def ==(other)
        self.class <= other.class && comparable == other.comparable
      end

      # Confirms that reuse of the resource did not change it in a way that breaks later reuse.
      # For example, this should fail if a reusable resource should have a specific name, but the name has been changed.
      def validate_reuse
        QA::Runtime::Logger.debug(["Validating a #{self.class.name} that was reused as #{reuse_as}", identifier].compact.join(' '))

        fresh_resource = reference_resource
        diff = reuse_validation_diff(fresh_resource)

        if diff.present?
          raise ResourceReuseError, <<~ERROR
            The reused #{self.class.name} resource does not have the attributes expected.
            The following change was found: #{diff}"
            The resource's web_url is #{web_url}.
            It was used in these tests: #{self.class.resources[reuse_as][:tests].to_a.join(', ')}
          ERROR
        end

      ensure
        fresh_resource.remove_via_api!
      end

      private

      # Creates a new resource that can be compared to a reused resource, using the post body of the original.
      # Must be implemented by classes that include this module.
      def reference_resource
        return super if defined?(super)

        raise NotImplementedError
      end

      # Confirms that the resource attributes specified in its fabricate_via_api! block will allow it to be reused.
      #
      # @return [nil] returns nil unless an error is raised
      def validate_reuse_preconditions
        return unless self.class.resources.key?(reuse_as)

        attributes = unique_identifiers.each_with_object({ proposed: {}, existing: {} }) do |id, attrs|
          proposed = public_send(id)
          existing = self.class.resources[reuse_as][:resource].public_send(id)

          next if proposed == existing

          attrs[:proposed][id] = proposed
          attrs[:existing][id] = existing
        end

        unless attributes[:proposed].empty? && attributes[:existing].empty?
          raise ResourceReuseError, "Reusable resources must use the same unique identifier(s). " \
            "The #{self.class.name} to be reused as :#{reuse_as} has the identifier(s) #{attributes[:proposed]} " \
            "but it should have #{attributes[:existing]}"
        end
      end

      # Compares the attributes of the current reused resource with a reference instance.
      #
      # @return [Hash] any differences between the resources.
      def reuse_validation_diff(other)
        original, reference = prepare_reuse_validation_diff(other)

        return if original == reference

        diff_values = original.to_a - reference.to_a
        diff_values.to_h
      end

      # Compares the current reusable resource to a reference instance, ignoring identifying unique attributes that
      # had to be changed.
      #
      # @return [Hash, Hash] the current and reference resource attributes, respectively.
      def prepare_reuse_validation_diff(other)
        original = self.reload!.comparable
        reference = other.reload!.comparable
        unique_identifiers.each { |id| reference[id] = original[id] }
        [original, reference]
      end

      # The attributes of the resource that should be the same whenever a test wants to reuse a resource. Must be
      # implemented by classes that include this module.
      #
      # @return [Array<Symbol>] the attribute names.
      def unique_identifiers
        return super if defined?(super)

        raise NotImplementedError
      end

      module ClassMethods
        # Includes the resources created/reused by this class in the specified collection
        def register(collection)
          collection[self.name] = resources
        end

        # The resources created/reused by this resource class.
        #
        # @return [Hash<Symbol, Hash>] the resources created/reused by this resource class.
        def resources
          @resources ||= {}
        end
      end
    end
  end
end
