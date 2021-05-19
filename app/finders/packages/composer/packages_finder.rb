# frozen_string_literal: true
module Packages
  module Composer
    class PackagesFinder < Packages::GroupPackagesFinder
      def initialize(current_user, group, params = {})
        @current_user = current_user
        @group = group
        @params = params
      end

      def execute
        packages_for_group_projects(installable_only: true).composer.preload_composer
      end
    end
  end
end
