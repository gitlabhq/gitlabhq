# frozen_string_literal: true

module Ci
  module Catalog
    # Service used for changing badge for organizations.
    # Run the service with a root level namespace and the verification level that you would change to.
    # Service will result in changing verification level on all
    # catalog resources in that namespace, including those in subgroups.
    class VerifyNamespaceService
      def initialize(namespace, verification_level)
        @namespace = namespace
        @verification_level = verification_level
        @errors = []
      end

      def execute
        verify_namespace_is_a_root
        verify_verification_level

        return ServiceResponse.error(message: errors.join(', ')) if errors.any?

        create_or_update_verified_namespace
        update_catalog_resources

        ServiceResponse.success
      end

      private

      attr_reader :namespace, :verification_level, :errors

      def verify_namespace_is_a_root
        return if namespace.root?

        errors << 'Please pass in the root namespace.'
      end

      def verify_verification_level
        levels = ::Ci::Catalog::VerifiedNamespace::VERIFICATION_LEVELS

        return if levels.key?(verification_level.to_sym)

        errors << "Please pass in a valid verification level: #{levels.keys.join(', ')}."
      end

      def create_or_update_verified_namespace
        verified_namespace = Ci::Catalog::VerifiedNamespace.find_or_create_by_namespace!(namespace)

        return if verified_namespace.verification_level == verification_level

        verified_namespace.update!(verification_level: verification_level)
      end

      def update_catalog_resources
        namespace.all_catalog_resources.update_all(verification_level: verification_level)
      end
    end
  end
end
