# frozen_string_literal: true

module API
  module Entities
    class UserPublic < Entities::User
      expose :last_sign_in_at, documentation: { type: 'DateTime', example: '2015-09-03T07:24:01.670Z' }
      expose :confirmed_at, documentation: { type: 'DateTime', example: '2015-09-03T07:24:01.670Z' }
      expose :last_activity_on, documentation: { type: 'DateTime', example: '2015-09-03T07:24:01.670Z' }
      expose :email, documentation: { type: 'String', example: 'john@example.com' }
      expose :theme_id, documentation: { type: 'Integer', example: 2 }
      expose :color_scheme_id, documentation: { type: 'Integer', example: 1 }
      expose :projects_limit, documentation: { type: 'Integer', example: 10 }
      expose :current_sign_in_at, documentation: { type: 'DateTime', example: '2015-09-03T07:24:01.670Z' }
      expose :identities, using: Entities::Identity
      expose :can_create_group?, as: :can_create_group, documentation: { type: 'Boolean', example: true }
      expose :can_create_project?, as: :can_create_project, documentation: { type: 'Boolean', example: true }

      expose :two_factor_enabled?, as: :two_factor_enabled, documentation: { type: 'Boolean', example: true }

      expose :external

      expose :private_profile, documentation: { type: 'Boolean', example: :null }
      expose :commit_email_or_default, as: :commit_email
      expose :preferred_language, documentation: { type: 'String', example: 'en' }
    end
  end
end

API::Entities::UserPublic.prepend_mod_with('API::Entities::UserPublic', with_descendants: true)
