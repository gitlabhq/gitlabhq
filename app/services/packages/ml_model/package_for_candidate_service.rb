# frozen_string_literal: true

module Packages
  module MlModel
    class PackageForCandidateService < ::Packages::CreatePackageService
      def execute
        candidate = params[:candidate]

        return unless candidate

        package = find_or_create_package!(
          ::Packages::Package.package_types['ml_model'],
          name: candidate.package_name,
          version: candidate.package_version
        )

        candidate.update!(package: package) if candidate.package_id != package.id

        package
      end
    end
  end
end
