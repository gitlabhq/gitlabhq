# frozen_string_literal: true

module Packages
  module Maven
    class CreatePackageService < ::Packages::CreatePackageService
      def execute
        return ERROR_RESPONSE_PACKAGE_PROTECTED if package_protected?(package_name: params[:name], package_type: :maven)

        app_group, _, app_name = params[:name].rpartition('/')
        app_group.tr!('/', '.')

        package = create_package!(
          ::Packages::Maven::Package,
          maven_metadatum_attributes: {
            path: params[:path],
            app_group: app_group,
            app_name: app_name,
            app_version: params[:version]
          }
        )

        ServiceResponse.success(payload: { package: package })
      rescue ActiveRecord::RecordInvalid, ActiveRecord::RecordNotUnique => e
        reason = case e
                 when ActiveRecord::RecordNotUnique
                   :name_taken
                 when ActiveRecord::RecordInvalid
                   e.record.errors&.of_kind?(:name, :taken) ? :name_taken : :invalid_parameter
                 end

        ServiceResponse.error(message: e.message, reason: reason)
      end
    end
  end
end
