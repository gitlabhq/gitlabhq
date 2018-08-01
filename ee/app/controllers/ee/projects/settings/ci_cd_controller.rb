module EE
  module Projects
    module Settings
      module CiCdController
        include ::API::Helpers::RelatedResourcesHelpers
        extend ::Gitlab::Utils::Override

        # rubocop:disable Gitlab/ModuleWithInstanceVariables
        override :show
        def show
          if project.feature_available?(:license_management)
            @license_management_url = expose_url(api_v4_projects_managed_licenses_path(id: @project.id))
          end

          super
        end
        # rubocop:enable Gitlab/ModuleWithInstanceVariables
      end
    end
  end
end
