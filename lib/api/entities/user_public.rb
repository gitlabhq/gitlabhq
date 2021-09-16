# frozen_string_literal: true

module API
  module Entities
    class UserPublic < Entities::User
      expose :last_sign_in_at
      expose :confirmed_at
      expose :last_activity_on
      expose :email
      expose :theme_id, :color_scheme_id, :projects_limit, :current_sign_in_at
      expose :identities, using: Entities::Identity
      expose :can_create_group?, as: :can_create_group
      expose :can_create_project?, as: :can_create_project
      expose :two_factor_enabled?, as: :two_factor_enabled
      expose :external
      expose :private_profile
      expose :commit_email
    end
  end
end

API::Entities::UserPublic.prepend_mod_with('API::Entities::UserPublic', with_descendants: true)
