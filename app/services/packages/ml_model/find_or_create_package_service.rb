# frozen_string_literal: true

module Packages
  module MlModel
    class FindOrCreatePackageService < ::Packages::CreatePackageService
      def execute
        find_or_create_package!(::Packages::Package.package_types['ml_model'])
      end
    end
  end
end
