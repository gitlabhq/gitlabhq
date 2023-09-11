# frozen_string_literal: true

module Packages
  module Npm
    class PackagesForUserFinder < ::Packages::GroupOrProjectPackageFinder
      def execute
        packages
      end

      private

      def packages
        base.npm
            .with_name(@params[:package_name])
      end
    end
  end
end
