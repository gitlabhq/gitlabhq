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
#
# TODO: Split this into multiple policies, one per supported user type
# https://gitlab.com/gitlab-org/gitlab/-/issues/463501
module Packages
  module Policies
    module DependencyProxy
      class GroupPolicy < ::GroupPolicy
        overrides(:read_dependency_proxy)

        desc "Deploy token with read access to dependency proxy"
        condition(:read_dependency_proxy_deploy_token) do
          deploy_token_user? && @user&.valid_for_dependency_proxy? && @user&.has_access_to_group?(@subject.group)
        end

        # TODO: Remove the deploy token check when we create a deploy token policy
        # https://gitlab.com/gitlab-org/gitlab/-/issues/463501
        desc "Non deploy token with read access to dependency proxy"
        condition(:read_dependency_proxy_personal_access_token) do
          !deploy_token_user? && (access_level(for_any_session: true) >= GroupMember::GUEST)
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

        def deploy_token_user?
          @user.is_a?(DeployToken)
        end
      end
    end
  end
end

Packages::Policies::DependencyProxy::GroupPolicy.prepend_mod_with('Packages::Policies::DependencyProxy::GroupPolicy')
