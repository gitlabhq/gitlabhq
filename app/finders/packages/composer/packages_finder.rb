# frozen_string_literal: true

module Packages
  module Composer
    class PackagesFinder < Packages::GroupPackagesFinder
      def initialize(
        current_user, group, params = { with_package_registry_enabled: true,
                                        packages_class: ::Packages::Composer::Package }
      )
        super(current_user, group, params)
      end

      def execute
        packages_for_group_projects(installable_only: true).preload_composer
      end
    end
  end
end
