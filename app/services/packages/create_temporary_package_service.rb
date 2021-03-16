# frozen_string_literal: true

module Packages
  class CreateTemporaryPackageService < ::Packages::CreatePackageService
    PACKAGE_VERSION = '0.0.0'

    def execute(package_type, name: 'Temporary.Package')
      create_package!(package_type,
        name: name,
        version: "#{PACKAGE_VERSION}-#{uuid}",
        status: 'processing'
      )
    end

    private

    def uuid
      SecureRandom.uuid
    end
  end
end
