# frozen_string_literal: true

module Packages
  module Debian
    class FindOrCreateIncomingService < ::Packages::CreatePackageService
      def execute
        find_or_create_package!(:debian, name: ::Packages::Debian::INCOMING_PACKAGE_NAME, version: nil)
      end
    end
  end
end
