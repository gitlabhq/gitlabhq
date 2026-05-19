# frozen_string_literal: true

class PersonalAccessTokenPolicy < BasePolicy
  condition(:is_owner) { user && subject.user_id == user.id && !subject.impersonation }

  desc "The actor has admin_service_accounts on the token user's provisioning scope"
  condition(:token_user_is_admin_managed_service_account) do
    next false unless user
    next false unless subject.user&.service_account?

    scope = subject.user.provisioned_by_group || subject.user.provisioned_by_project
    next false unless scope

    can?(:admin_service_accounts, scope)
  end

  rule { (is_owner | admin | token_user_is_admin_managed_service_account) & ~blocked }.policy do
    enable :revoke_personal_access_token
  end
end

PersonalAccessTokenPolicy.prepend_mod
