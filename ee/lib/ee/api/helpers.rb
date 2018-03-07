module EE
  module API
    module Helpers
      extend ::Gitlab::Utils::Override

      override :current_user
      def current_user
        strong_memoize(:current_user) do
          user = super

          if user
            ::Gitlab::Database::LoadBalancing::RackMiddleware
              .stick_or_unstick(env, :user, user.id)
          end

          user
        end
      end

      def check_project_feature_available!(feature)
        not_found! unless user_project.feature_available?(feature)
      end

      def check_sha_param!(params, merge_request)
        if params[:sha] && merge_request.diff_head_sha != params[:sha]
          render_api_error!("SHA does not match HEAD of source branch: #{merge_request.diff_head_sha}", 409)
        end
      end

      # Normally, only admin users should have access to see LDAP
      # groups. However, due to the "Allow group owners to manage LDAP-related
      # group settings" setting, any group owner can sync LDAP groups with
      # their project.
      #
      # In the future, we should also check that the user has access to manage
      # a specific group so that we can use the Ability class.
      def authenticated_with_ldap_admin_access!
        authenticate!

        forbidden! unless current_user.admin? ||
            ::Gitlab::CurrentSettings.current_application_settings
              .allow_group_owners_to_manage_ldap
      end
    end
  end
end
