# rubocop:disable Gitlab/ModuleWithInstanceVariables
module EE
  module Admin
    module DashboardController
      extend ActiveSupport::Concern

      prepended do
        before_action :set_roles_count, only: [:index]
      end

      private

      def set_roles_count
        @admin_count = ::User.admins.count
        @roles_count = ::ProjectAuthorization.roles_stats
      end
    end
  end
end
