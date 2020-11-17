# frozen_string_literal: true

module Packages
  module Generic
    class FindOrCreatePackageService < ::Packages::CreatePackageService
      def execute
        find_or_create_package!(::Packages::Package.package_types['generic']) do |package|
          if params[:build].present?
            package.build_infos.new(pipeline: params[:build].pipeline)
          end
        end
      end
    end
  end
end
