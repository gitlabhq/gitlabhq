# frozen_string_literal: true

module Packages
  module Generic
    class FindOrCreatePackageService < ::Packages::CreatePackageService
      def execute
        find_or_create_package!(::Packages::Package.package_types['generic'])
      end
    end
  end
end
