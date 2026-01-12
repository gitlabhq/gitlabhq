# frozen_string_literal: true

module API
  class Avatar < ::API::Base
    feature_category :user_profile
    urgency :medium

    resource :avatar do
      desc 'Return avatar url for a user' do
        success Entities::Avatar
        tags %w[avatars]
      end
      params do
        requires :email, type: String, desc: 'Public email address of the user'
        optional :size, type: Integer, desc: 'Single pixel dimension for Gravatar images'
      end
      route_setting :authorization, permissions: :read_avatar, boundary_type: :user
      get do
        forbidden!('Unauthorized access') unless can?(current_user, :read_users_list)

        user = User.find_by_public_email(params[:email])
        user ||= User.new(email: params[:email])

        present user, with: Entities::Avatar, size: params[:size]
      end
    end
  end
end
