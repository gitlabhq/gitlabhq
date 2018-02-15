# rubocop:disable Gitlab/ModuleWithInstanceVariables
module EE
  module Admin
    module DashboardController
      extend ActiveSupport::Concern

      def stats
        @admin_count = ::User.admins.count
        @roles_count = ::ProjectAuthorization.roles_stats
      end
    end
  end
end
