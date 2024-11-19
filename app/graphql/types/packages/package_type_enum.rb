# frozen_string_literal: true

module Types
  module Packages
    class PackageTypeEnum < BaseEnum
      PACKAGE_TYPE_NAMES = {
        pypi: 'PyPI',
        npm: 'npm',
        terraform_module: 'Terraform Module'
      }.freeze

      ::Packages::Package.package_types.keys.each do |package_type|
        type_name = PACKAGE_TYPE_NAMES.fetch(package_type.to_sym, package_type.capitalize)
        value package_type.to_s.upcase,
          description: "Packages from the #{type_name} package manager",
          value: package_type.to_s
      end
    end
  end
end
