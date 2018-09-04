# frozen_string_literal: true
module EE
  module Projects
    module Settings
      module CiCdController
        include ::API::Helpers::RelatedResourcesHelpers
        extend ::Gitlab::Utils::Override
        extend ActiveSupport::Concern

        prepended do
          before_action :assign_variables_to_gon, only: :show
          before_action :define_protected_env_variables, only: :show
        end

        # rubocop:disable Gitlab/ModuleWithInstanceVariables
        override :show
        def show
          if project.feature_available?(:license_management)
            @license_management_url = expose_url(api_v4_projects_managed_licenses_path(id: @project.id))
          end

          super
        end

        private

        # rubocop: disable CodeReuse/ActiveRecord
        def define_protected_env_variables
          @protected_environments = @project.protected_environments.order(:name)
          @protected_environment = @project.protected_environments.new
        end
        # rubocop: enable CodeReuse/ActiveRecord

        def assign_variables_to_gon
          gon.push(current_project_id: project.id)
          gon.push(deploy_access_levels: environment_dropdown.roles_hash)
          gon.push(search_unprotected_environments_url: search_project_protected_environments_path(@project))
        end

        def environment_dropdown
          @environment_dropdown ||= ProtectedEnvironments::EnvironmentDropdownService
        end
      end
    end
  end
end
