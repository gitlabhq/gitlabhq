# frozen_string_literal: true

module Admin
  module Organizations
    class UsersController < Admin::Organizations::ApplicationController
      extend Gitlab::Utils::Override

      include Admin::UsersActions

      def index
        super

        @organization = ::Current.organization

        render 'admin/users/index' unless performed?
      end

      def show
        render 'admin/users/show'
      end

      def edit
        user
      end

      def update
        result = ::Users::UpdateService.new(current_user, user_params.merge(user: user)).execute

        if result[:status] == :success
          redirect_to admin_user_path(user), notice: _('User was successfully updated.')
        else
          render :edit
        end
      end

      private

      def user_params
        params.require(:user).permit(
          organization_users_attributes: [:id, :organization_id, :access_level]
        )
      end

      override :filter_users
      def filter_users
        super.member_of_organization(::Current.organization)
      end

      override :impersonation_available?
      def impersonation_available?
        false
      end

      override :show_invite_organization_user_button?
      def show_invite_organization_user_button?
        current_user.can?(:create_organization_user, ::Current.organization.organization_users.new)
      end
    end
  end
end

Admin::Organizations::UsersController.prepend_mod
