# frozen_string_literal: true

module Packages
  module Nuget
    class CreatePackageService < ::Packages::CreatePackageService
      TEMPORARY_PACKAGE_NAME = 'NuGet.Temporary.Package'
      PACKAGE_VERSION = '0.0.0'

      def execute
        create_package!(:nuget,
          name: TEMPORARY_PACKAGE_NAME,
          version: "#{PACKAGE_VERSION}-#{uuid}"
        )
      end

      private

      def uuid
        SecureRandom.uuid
      end
    end
  end
end
