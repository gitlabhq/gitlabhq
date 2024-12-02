# frozen_string_literal: true

module Packages
  module Maven
    class CreatePackageService < ::Packages::CreatePackageService
      def execute
        app_group, _, app_name = params[:name].rpartition('/')
        app_group.tr!('/', '.')

        package = create_package!(:maven,
          maven_metadatum_attributes: {
            path: params[:path],
            app_group: app_group,
            app_name: app_name,
            app_version: params[:version]
          }
        )

        ServiceResponse.success(payload: { package: package })
      rescue ActiveRecord::RecordInvalid => e
        reason = e.record&.errors&.of_kind?(:name, :taken) ? :name_taken : :invalid_parameter

        ServiceResponse.error(message: e.message, reason: reason)
      end
    end
  end
end
