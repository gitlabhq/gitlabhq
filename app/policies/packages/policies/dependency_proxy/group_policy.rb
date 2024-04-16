# frozen_string_literal: true

# The policies defined in GroupPolicy is used in GraphQL requests
# With a GraphQL request, the user is always a human User
#
# With JWT requests, we can be dealing with any of the following:
# - a PrAT for a human
# - a PrAT for a service account
# - a GrAT
# - a Group DeployToken
#
# We use this custom policy class for JWT requests
module Packages
  module Policies
    module DependencyProxy
      class GroupPolicy < ::GroupPolicy
        overrides(:read_dependency_proxy)

        desc "Deploy token with read access to dependency proxy"
        condition(:read_dependency_proxy_deploy_token) do
          @user.is_a?(DeployToken) && @user&.valid_for_dependency_proxy? && @user&.has_access_to_group?(@subject.group)
        end

        desc "Personal access or group access token with read access to dependency proxy"
        condition(:read_dependency_proxy_personal_access_token) do
          user_is_personal_access_token? &&
            (
              user.user.human? ||
              user.user.service_account? ||
              (user.user.project_bot? && user.user.resource_bot_resource.is_a?(::Group))
            ) &&
            (access_level(for_any_session: true) >= GroupMember::GUEST)
        end

        condition(:dependency_proxy_disabled, scope: :subject) do
          !@subject.dependency_proxy_feature_available?
        end

        rule { dependency_proxy_disabled }.prevent :read_dependency_proxy

        rule do
          read_dependency_proxy_personal_access_token | read_dependency_proxy_deploy_token
        end.enable :read_dependency_proxy

        rule do
          ~read_dependency_proxy_personal_access_token & ~read_dependency_proxy_deploy_token
        end.prevent :read_dependency_proxy

        def access_level(for_any_session: false)
          return GroupMember::NO_ACCESS if @user.nil?

          @access_level ||= lookup_access_level!(for_any_session: for_any_session)
        end

        def lookup_access_level!(_)
          @subject.max_member_access_for_user(@user.user)
        end

        def user_is_personal_access_token?
          user.is_a?(PersonalAccessToken)
        end
      end
    end
  end
end

Packages::Policies::DependencyProxy::GroupPolicy.prepend_mod_with('Packages::Policies::DependencyProxy::GroupPolicy')
