# frozen_string_literal: true

module Packages
  module Npm
    class PackagesForUserFinder < ::Packages::GroupOrProjectPackageFinder
      extend ::Gitlab::Utils::Override

      def execute
        packages
      end

      private

      def packages
        if Feature.enabled?(:npm_extract_npm_package_model, Feature.current_request)
          base.with_name(@params[:package_name])
        else
          base.npm
              .with_name(@params[:package_name])
        end
      end

      override :group_packages
      def group_packages
        packages_visible_to_user(@current_user, within_group: @project_or_group, with_package_registry_enabled: true)
      end

      override :packages_class
      def packages_class
        if Feature.enabled?(:npm_extract_npm_package_model, Feature.current_request)
          ::Packages::Npm::Package
        else
          super
        end
      end
    end
  end
end
