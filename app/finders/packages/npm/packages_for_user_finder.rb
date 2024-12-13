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
        base.with_name(@params[:package_name])
      end

      override :group_packages
      def group_packages
        packages_visible_to_user(@current_user, within_group: @project_or_group, with_package_registry_enabled: true)
      end

      override :packages_class
      def packages_class
        ::Packages::Npm::Package
      end
    end
  end
end
