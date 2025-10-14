# frozen_string_literal: true

module Mutations
  module Packages
    module DeleteProtection
      extend ActiveSupport::Concern

      private

      DELETION_PROTECTED_ERROR_MESSAGE = 'Package is deletion protected.'

      def protected_for_delete?(package, in_project: nil)
        project = in_project || package.project
        return false if Feature.disabled?(:packages_protected_packages_delete, project)

        service_response = ::Packages::Protection::CheckRuleExistenceService.for_delete(
          current_user: current_user,
          project: project,
          params: { package_name: package.name, package_type: package.package_type }
        ).execute

        service_response.success? && service_response[:protection_rule_exists?]
      end

      def deletion_protected_error_message(package_name = nil)
        return DELETION_PROTECTED_ERROR_MESSAGE if package_name.blank?

        "Package '#{package_name}' is deletion protected."
      end
    end
  end
end
