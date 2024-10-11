# frozen_string_literal: true

module Admin
  class UserEntity < API::Entities::UserSafe
    include RequestAwareEntity
    include ::UsersHelper
    include UserActionsHelper

    expose :created_at
    expose :email
    expose :last_activity_on
    expose :avatar_url
    expose :note
    expose :badges do |user|
      user_badges_in_admin_section(user)
    end

    expose :projects_count do |user|
      user.authorized_projects.length
    end

    expose :actions do |user|
      admin_actions(user)
    end

    private

    def current_user
      options[:current_user]
    end
  end
end

Admin::UserEntity.prepend_mod_with('Admin::UserEntity')
