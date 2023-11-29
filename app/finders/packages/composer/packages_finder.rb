# frozen_string_literal: true
module Packages
  module Composer
    class PackagesFinder < Packages::GroupPackagesFinder
      def initialize(current_user, group, params = { package_type: :composer, with_package_registry_enabled: true })
        super(current_user, group, params)
      end

      def execute
        packages_for_group_projects(installable_only: true).preload_composer
      end
    end
  end
end
