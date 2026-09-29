# frozen_string_literal: true

module Admin
  module Organizations
    class UsersController < Admin::Organizations::ApplicationController
      extend Gitlab::Utils::Override

      include Admin::UsersActions

      INVITE_SEARCH_PER_PAGE = 20

      before_action :check_autocomplete_users_rate_limit!, only: [:invite_search]

      def index
        super

        @organization = ::Current.organization

        render 'admin/organizations/users/index' unless performed?
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

      def invite_search
        users = ::Organizations::InviteUsersFinder.new(
          organization: ::Current.organization,
          current_user: current_user,
          search: invite_search_params[:search]
        ).execute.page(1).per(INVITE_SEARCH_PER_PAGE)

        render json: UserSerializer.new(current_user: current_user).represent(users)
      end

      private

      def invite_search_params
        params.permit(:search)
      end

      # Shares the budget of the shared users autocomplete endpoint this search replaced,
      # so an admin-tuned autocomplete_users_limit keeps covering the invite modal.
      def check_autocomplete_users_rate_limit!
        check_rate_limit!(:autocomplete_users, scope: { user: current_user })
      end

      def user_params
        params.require(:user).permit(
          organization_users_attributes: [:id, :organization_id, :access_level]
        )
      end

      override :filter_users
      def filter_users
        super.member_of_organization(::Current.organization)
      end

      override :user
      def user
        @user ||= find_routable!(
          User,
          safe_params[:id],
          request.fullpath,
          extra_authorization_proc: ->(user) { user.member_of_organization?(::Current.organization) }
        )
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
