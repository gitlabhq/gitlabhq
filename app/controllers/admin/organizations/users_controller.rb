# frozen_string_literal: true

module Admin
  module Organizations
    class UsersController < Admin::Organizations::ApplicationController
      extend Gitlab::Utils::Override

      include Admin::UsersActions

      def index
        super

        render 'admin/users/index' unless performed?
      end

      def show
        render 'admin/users/show'
      end

      private

      override :filter_users
      def filter_users
        super.member_of_organization(::Current.organization)
      end

      override :cohorts_tab_available?
      def cohorts_tab_available?
        false
      end

      override :impersonation_available?
      def impersonation_available?
        false
      end
    end
  end
end

Admin::Organizations::UsersController.prepend_mod
