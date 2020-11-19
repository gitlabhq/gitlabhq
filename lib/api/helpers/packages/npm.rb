# frozen_string_literal: true

module API
  module Helpers
    module Packages
      module Npm
        include Gitlab::Utils::StrongMemoize
        include ::API::Helpers::PackagesHelpers

        NPM_ENDPOINT_REQUIREMENTS = {
          package_name: API::NO_SLASH_URL_PART_REGEX
        }.freeze

        def endpoint_scope
          params[:id].present? ? :project : :instance
        end

        def project
          strong_memoize(:project) do
            case endpoint_scope
            when :project
              user_project
            when :instance
              # Simulate the same behavior as #user_project by re-using #find_project!
              # but take care if the project_id is nil as #find_project! is not designed
              # to handle it.
              project_id = project_id_or_nil

              not_found!('Project') unless project_id

              find_project!(project_id)
            end
          end
        end

        def project_or_nil
          # mainly used by the metadata endpoint where we need to get a project
          # and return nil if not found (no errors should be raised)
          strong_memoize(:project_or_nil) do
            next unless project_id_or_nil

            find_project(project_id_or_nil)
          end
        end

        def project_id_or_nil
          strong_memoize(:project_id_or_nil) do
            case endpoint_scope
            when :project
              params[:id]
            when :instance
              ::Packages::Package.npm
                                .with_name(params[:package_name])
                                .first
                                &.project_id
            end
          end
        end
      end
    end
  end
end
