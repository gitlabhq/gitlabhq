# frozen_string_literal: true

module QA
  module Resource
    #
    # This module includes methods that allow resource classes to be reused safely. It should be prepended to a new
    # reusable version of an existing resource class. See Resource::Project and ReusableResource::Project for an example
    #
    module Reusable
      attr_accessor :reuse,
                    :reuse_as

      ResourceReuseError = Class.new(RuntimeError)

      def self.prepended(base)
        base.extend(ClassMethods)
      end

      # Gets an existing resource if it exists and the parameters of the new specification of the resource are valid.
      # Creates a new instance of the resource if it does not exist.
      #
      # @return [String] The URL of the resource.
      def fabricate_via_api!
        validate_reuse_preconditions

        resource_web_url(api_get)
      rescue Errors::ResourceNotFoundError
        super
      ensure
        self.class.resources[reuse_as] = self
      end

      # Including classes must confirm that the resource can be reused as defined. For example, a project can't be
      # fabricated with a unique name.
      #
      # @return [nil]
      def validate_reuse_preconditions
        return super if defined?(super)

        raise NotImplementedError
      end

      module ClassMethods
        # Removes all created resources of this type.
        #
        # @return [Hash<Symbol, QA::Resource>] the resources that were to be removed.
        def remove_all_via_api!
          resources.each do |reuse_as, resource|
            QA::Runtime::Logger.debug("#{self.name} - removing resource reused as :#{reuse_as}")
            next QA::Runtime::Logger.debug("#{self.name} reused as :#{reuse_as} has already been removed.") unless resource.exists?

            resource.method(:remove_via_api!).super_method.call
          end
        end

        # The resources created by this resource class.
        #
        # @return [Hash<Symbol, QA::Resource>] the resources created by this resource class.
        def resources
          @resources ||= {}
        end
      end
    end
  end
end
