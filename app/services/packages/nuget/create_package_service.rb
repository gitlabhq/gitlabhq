# frozen_string_literal: true

module Packages
  module Nuget
    class CreatePackageService < BaseService
      TEMPORARY_PACKAGE_NAME = 'NuGet.Temporary.Package'
      PACKAGE_VERSION = '0.0.0'

      def execute
        project.packages.nuget.create!(
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
