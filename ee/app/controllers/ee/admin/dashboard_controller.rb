# rubocop:disable Gitlab/ModuleWithInstanceVariables
module EE
  module Admin
    module DashboardController
      extend ActiveSupport::Concern
      extend ::Gitlab::Utils::Override

      override :index
      def index
        super

        @license = License.current
      end

      def stats
        @admin_count = ::User.admins.count
        @roles_count = ::ProjectAuthorization.roles_stats
      end
    end
  end
end
