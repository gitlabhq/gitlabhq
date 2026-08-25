# frozen_string_literal: true

module API
  module Entities
    class Member < Grape::Entity
      expose :user, merge: true, using: UserBasic
      expose :access_level
      expose :created_at
      expose :created_by, with: UserBasic, expose_nil: false,
        if: ->(member) { member.is_source_accessible_to_current_user }
      expose :expires_at
      expose :two_factor_enabled,
        documentation: { type: 'Boolean' },
        if: ->(member, opts) {
          member.user && Ability.allowed?(opts[:current_user], :read_two_factor_member,
            opts[:source] || member.source)
        } do |member, _opts|
          member.user.two_factor_enabled?
        end
    end
  end
end

API::Entities::Member.prepend_mod_with('API::Entities::Member', with_descendants: true)
