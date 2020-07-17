# frozen_string_literal: true

module Types
  class PackageTypeEnum < BaseEnum
    ::Packages::Package.package_types.keys.each do |package_type|
      value package_type.to_s.upcase, "Packages from the #{package_type} package manager", value: package_type.to_s
    end
  end
end
