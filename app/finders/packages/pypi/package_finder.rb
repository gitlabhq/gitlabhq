# frozen_string_literal: true

module Packages
  module Pypi
    class PackageFinder < ::Packages::GroupOrProjectPackageFinder
      def execute
        packages.by_file_name_and_sha256(@params[:filename], @params[:sha256])
      end

      private

      def packages
        base.pypi.has_version
      end
    end
  end
end
