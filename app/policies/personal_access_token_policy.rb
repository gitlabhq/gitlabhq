# frozen_string_literal: true

class PersonalAccessTokenPolicy < BasePolicy
  condition(:is_owner) { user && subject.user_id == user.id && !subject.impersonation }

  rule { (is_owner | admin) & ~blocked }.policy do
    enable :read_token
    enable :revoke_token
  end
end

PersonalAccessTokenPolicy.prepend_mod
