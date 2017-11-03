module EE
  module Gitlab
    module GitAccess
      def check(cmd, changes)
        raise NotImplementedError.new unless defined?(super)

        check_geo_license!

        super
      end

      def can_read_project?
        raise NotImplementedError.new unless defined?(super)

        return geo_node_key.active? if geo_node_key?
        return true if actor == :geo

        super
      end

      protected

      def user
        raise NotImplementedError.new unless defined?(super)

        return nil if geo?

        super
      end

      private

      def check_download_access!
        raise NotImplementedError.new unless defined?(super)

        return if geo?

        super
      end

      def check_active_user!
        raise NotImplementedError.new unless defined?(super)

        return if geo?

        super
      end

      def check_geo_license!
        if ::Gitlab::Geo.secondary? && !::Gitlab::Geo.license_allows?
          raise ::Gitlab::GitAccess::UnauthorizedError, 'Your current license does not have GitLab Geo add-on enabled.'
        end
      end

      def geo_node_key
        actor if geo_node_key?
      end

      def geo_node_key?
        actor.is_a?(::GeoNodeKey)
      end

      def geo?
        geo_node_key? || actor == :geo
      end
    end
  end
end
