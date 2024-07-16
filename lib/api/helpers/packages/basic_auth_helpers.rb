# frozen_string_literal: true

module API
  module Helpers
    module Packages
      module BasicAuthHelpers
        extend ::Gitlab::Utils::Override

        module Constants
          AUTHENTICATE_REALM_HEADER = 'WWW-Authenticate'
          AUTHENTICATE_REALM_NAME = 'Basic realm="GitLab Packages Registry"'
        end

        include Constants
        include Gitlab::Utils::StrongMemoize

        def authorized_user_project(action: :read_project)
          strong_memoize("authorized_user_project_#{action}") do
            authorized_project_find!(action: action)
          end
        end

        def authorized_project_find!(action: :read_project)
          project = find_project(params[:id])

          return unauthorized_or! { not_found! } unless project

          case action
          when :read_package
            unless can?(current_user, :read_package, project&.packages_policy_subject)
              # guest users can have :read_project but not :read_package
              return forbidden! if can?(current_user, :read_project, project)

              return unauthorized_or! { not_found! }
            end
          else
            return unauthorized_or! { not_found! } unless can?(current_user, action, project)
          end

          project
        end

        def find_authorized_group!(action: :read_group)
          strong_memoize_with(:find_authorized_group, action) do
            group = find_group(params[:id])

            subject = case action
                      when :read_package_within_public_registries
                        group&.packages_policy_subject
                      when :read_group
                        group
                      end

            unless group && can?(current_user, action, subject)
              break unauthorized_or! { not_found! }
            end

            group
          end
        end

        def authorize!(action, subject = :global, reason = nil)
          return if can?(current_user, action, subject)

          unauthorized_or! { forbidden!(reason) }
        end

        def unauthorized_or!
          current_user ? yield : unauthorized!
        end

        override :unauthorized!
        def unauthorized!
          header(AUTHENTICATE_REALM_HEADER, AUTHENTICATE_REALM_NAME)
          super
        end
      end
    end
  end
end
