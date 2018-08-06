module EE
  module Gitlab
    module GitAccess
      prepend GeoGitAccess
      extend ::Gitlab::Utils::Override

      override :check
      def check(cmd, changes)
        check_geo_license!

        super
      end

      override :can_read_project?
      def can_read_project?
        return true if geo?

        super
      end

      protected

      override :user
      def user
        return nil if geo?

        super
      end

      private

      override :check_download_access!
      def check_download_access!
        return if geo?

        super
      end

      override :check_active_user!
      def check_active_user!
        return if geo?

        super
      end

      def check_geo_license!
        if ::Gitlab::Geo.secondary? && !::Gitlab::Geo.license_allows?
          raise ::Gitlab::GitAccess::UnauthorizedError, 'Your current license does not have GitLab Geo add-on enabled.'
        end
      end

      def geo?
        actor == :geo
      end

      override :authed_via_jwt?
      def authed_via_jwt?
        geo?
      end
    end
  end
end
