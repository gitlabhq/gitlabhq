# frozen_string_literal: true

class PersonalAccessTokenPolicy < BasePolicy
  condition(:is_owner) { user && subject.user_id == user.id }

  rule { is_owner | admin }.policy do
    enable :read_token
  end
end
