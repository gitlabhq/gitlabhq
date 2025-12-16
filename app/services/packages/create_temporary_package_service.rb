# frozen_string_literal: true

module Packages
  class CreateTemporaryPackageService < ::Packages::CreatePackageService
    PACKAGE_VERSION = '0.0.0'

    def execute(packages_class, name: 'Temporary.Package')
      create_package!(
        packages_class,
        name: name,
        version: version,
        status: 'processing'
      )
    end

    private

    def version
      "#{PACKAGE_VERSION}-#{SecureRandom.uuid}"
    end
  end
end
