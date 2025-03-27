# frozen_string_literal: true

module Packages
  module Conan
    class PackageFileFinder < ::Packages::Conan::PackageFilesFinder
      extend ::Gitlab::Utils::Override

      override :execute
      def execute
        package_files.last
      end

      def execute!
        package_files.last!
      end
    end
  end
end
